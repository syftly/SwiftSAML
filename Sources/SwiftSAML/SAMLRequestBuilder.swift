import Foundation

public struct SAMLRequestBuilder {
    let config: SAMLConfig
    
    public init(config: SAMLConfig) {
        self.config = config
    }
    
    public func buildAuthnRequestURL() -> URL? {
        guard let encodedSAMLRequest = buildAndEncodeAuthnRequest(config: config) else {
            return nil
        }
        return constructRedirectURL(encodedSAMLRequest: encodedSAMLRequest, idpSSOURL: config.idpMetadata.ssoURL)
    }
    
    private func buildAuthnRequest(config: SAMLConfig) -> String {
        let requestId = UUID().uuidString
        let issueInstant = ISO8601DateFormatter().string(from: Date())

        return """
        <samlp:AuthnRequest xmlns="urn:oasis:names:tc:SAML:2.0:protocol"
                      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                      xmlns:xs="http://www.w3.org/2001/XMLSchema"
                      ID="\(requestId)"
                      Version="2.0"
                      IssueInstant="\(issueInstant)"
                      Destination="\(config.idpMetadata.ssoURL)"
                      ProtocolBinding="urn:oasis:names:tc:SAML:2.0:bindings:\(config.binding.rawValue)"
                      AssertionConsumerServiceURL="\(config.assertionConsumerServiceURL)">
            <saml:Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">\(config.idpMetadata.entityID)</saml:Issuer>
            <saml:NameIDPolicy Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress" AllowCreate="true"/>
        </samlp:AuthnRequest>
        """
    }

    private func deflateAndEncode(xml: String) -> String? {
        guard let data = xml.data(using: .utf8) else { return nil }
        guard let deflated = data.deflated() else { return nil }
        return deflated.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }

    private func buildAndEncodeAuthnRequest(config: SAMLConfig) -> String? {
        let authnRequestXML = buildAuthnRequest(config: config)
        print(authnRequestXML)
        return deflateAndEncode(xml: authnRequestXML)
    }

    private func constructRedirectURL(encodedSAMLRequest: String, idpSSOURL: URL) -> URL? {
        var components = URLComponents(url: idpSSOURL, resolvingAgainstBaseURL: false)
        let queryItem = URLQueryItem(name: "SAMLRequest", value: encodedSAMLRequest)
        components?.queryItems = [queryItem]
        return components?.url
    }
}
