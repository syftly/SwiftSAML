import Foundation

public struct SAMLConfig {
    var assertionConsumerServiceURL: String
    var idpMetadata: IDPMetadata
    var binding: SAMLProtocolBinding
    
    public init(assertionConsumerServiceURL: String, idpMetadata: IDPMetadata, binding: SAMLProtocolBinding) {
        self.assertionConsumerServiceURL = assertionConsumerServiceURL
        self.idpMetadata = idpMetadata
        self.binding = binding
    }
}
