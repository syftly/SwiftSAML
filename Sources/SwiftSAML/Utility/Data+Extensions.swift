import Foundation
import zlib

extension Data {
    func deflated() -> Self? {
        var stream = z_stream()
        var deflated = Data()
        
        let streamSize = Int32(MemoryLayout<z_stream>.size)
        return self.withUnsafeBytes { (inputBytes: UnsafeRawBufferPointer) -> Data? in
            guard let inputBuffer = inputBytes.bindMemory(to: Bytef.self).baseAddress else { return nil }
            
            stream.next_in = UnsafeMutablePointer(mutating: inputBuffer)
            stream.avail_in = uInt(self.count)
            
            // Initialize the compression stream
            if deflateInit_(&stream, Z_DEFAULT_COMPRESSION, ZLIB_VERSION, streamSize) != Z_OK {
                return nil
            }
            
            var outputBuffer = [Bytef](repeating: 0, count: self.count * 2)  // Larger buffer as a common practice
            var safeOutputBuffer = outputBuffer

            while true {
                let deflatedResult = outputBuffer.withUnsafeMutableBytes { outputPointer -> Data? in
                    stream.next_out = outputPointer.baseAddress?.assumingMemoryBound(to: Bytef.self)
                    stream.avail_out = uInt(outputPointer.count)

                    let res = deflate(&stream, Z_FINISH)
                    if res == Z_STREAM_END {
                        return Data(bytes: outputPointer.baseAddress!, count: safeOutputBuffer.count - Int(stream.avail_out))
                    }
                    if res != Z_OK {
                        deflateEnd(&stream)
                        return nil  // If deflate fails, end and return nil
                    }

                    if stream.avail_out == 0 {
                        // No space left in the output buffer
                        return nil
                    }
                    
                    return nil
                }

                if let result = deflatedResult {
                    deflated.append(result)
                }

                if deflatedResult != nil || stream.avail_out != 0 {
                    break  // If deflation is complete or failed, exit loop
                }

                // Resize the buffer if it was fully used
                let oldSize = outputBuffer.count
                outputBuffer.append(contentsOf: [Bytef](repeating: 0, count: oldSize))
            }
            
            deflateEnd(&stream)
            return deflated
        }
    }
}
