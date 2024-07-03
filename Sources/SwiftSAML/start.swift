//
//  File.swift
//  
//
//  Created by Will Morris on 5/6/24.
//
import Foundation


enum Start {
    static func main() {
        let config = SAMLConfig(
            assertionConsumerServiceURL: "http://127.0.0.1:8080/saml",
            idpMetadata: .mockSAML,
            binding: .post
        )
                
        let request = SAMLRequestBuilder(config: config).buildAuthnRequestURL()
        
        print(request ?? "Failed")
    }
}
