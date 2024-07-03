import Foundation
import SWXMLHash
import Crypto

struct SAMLResponseHandler {
    
    func processResponse(responseXML: String, publicKeyPEM: String) -> SAMLAssertion? {
        guard let xmlDoc = parseXML(xml: responseXML) else {
            print("Failed to parse XML")
            return nil
        }
        
        guard validateResponse(xmlDoc: xmlDoc, publicKeyPEM: publicKeyPEM, expectedAudience: "") else {
            print("SAML Response validation failed")
            return nil
        }
        
        if let assertion = extractAssertion(xmlDoc: xmlDoc) {
            return assertion
        } else {
            print("Failed to extract assertion from SAML Response")
            return nil
        }
    }

    private func parseXML(xml: String) -> XMLIndexer? {
        let xmlIndexer = XMLHash.parse(xml)
        return xmlIndexer
    }
    
    private func validateResponse(xmlDoc: XMLIndexer, publicKeyPEM: String, expectedAudience: String) -> Bool {
        guard let signedData = extractSignedData(xmlDoc: xmlDoc),
              let signature = extractSignature(xmlDoc: xmlDoc),
              let conditions = extractConditions(xmlDoc: xmlDoc),
              validateSignature(signedData: signedData, signature: signature, publicKeyPEM: publicKeyPEM),
              validateConditions(conditions: conditions, expectedAudience: expectedAudience) else {
            return false
        }
        
        return true
    }

    private func extractSignedData(xmlDoc: XMLIndexer) -> Data? {
        guard let assertionXML = xmlDoc["samlp:Response"]["saml:Assertion"].element?.description else {
            print("No assertion found to extract for signature validation.")
            return nil
        }

        guard let canonicalizedXML = canonicalizeXML(xmlString: assertionXML) else {
            print("Failed to canonicalize XML.")
            return nil
        }

        let signedData = canonicalizedXML.data(using: .utf8)
        return signedData
    }
    
    // This function is a placeholder. You need to replace it with actual XML canonicalization logic.
    private func canonicalizeXML(xmlString: String) -> String? {
        // Canonicalization logic goes here
        // This could involve calling an external command-line tool or using a library
        return xmlString  // Return the input string for placeholder purposes
    }
    
    private func extractSignature(xmlDoc: XMLIndexer) -> Data? {
        if let signatureString = xmlDoc["samlp:Response"]["Signature"]["SignatureValue"].element?.text {
            return Data(base64Encoded: signatureString)
        } else if let signatureString = xmlDoc["samlp:Response"]["saml:Assertion"]["Signature"]["SignatureValue"].element?.text {
            return Data(base64Encoded: signatureString)
        } else {
            print("Failed to locate the signature in the provided SAML response.")
            return nil
        }
    }

    private func extractConditions(xmlDoc: XMLIndexer) -> SAMLConditions? {
        let conditionsElement = xmlDoc["samlp:Response"]["saml:Assertion"]["saml:Conditions"]

        guard let notBeforeString = conditionsElement.element?.attribute(by: "NotBefore")?.text,
              let notOnOrAfterString = conditionsElement.element?.attribute(by: "NotOnOrAfter")?.text,
              let notBefore = ISO8601DateFormatter().date(from: notBeforeString),
              let notOnOrAfter = ISO8601DateFormatter().date(from: notOnOrAfterString) else {
            print("Failed to parse condition dates from SAML Response")
            return nil
        }

        let audienceRestrictions = conditionsElement["saml:AudienceRestriction"]["saml:Audience"]
            .all
            .compactMap { element in
                if let audienceText = element.element?.text {
                    return SAMLAudienceRestriction(audience: audienceText)
                }
                return nil
            }

        if audienceRestrictions.isEmpty {
            print("No audience restrictions found, which might be an issue depending on the SAML policy.")
        }

        return SAMLConditions(
            notBefore: notBefore,
            notOnOrAfter: notOnOrAfter,
            audienceRestrictions: audienceRestrictions
        )
    }
    
    func validateSignature(signedData: Data, signature: Data, publicKeyPEM: String) -> Bool {
        do {
            let publicKey = try P256.Signing.PublicKey(pemRepresentation: publicKeyPEM)
            let ecSignature = try P256.Signing.ECDSASignature(derRepresentation: signature)
            return publicKey.isValidSignature(ecSignature, for: signedData)
        } catch {
            print("Error during signature validation: \(error)")
            return false
        }
    }

    func validateConditions(conditions: SAMLConditions, expectedAudience: String) -> Bool {
        let now = Date()
        let isTimeValid = (conditions.notBefore <= now && conditions.notOnOrAfter > now)
        
        let isAudienceValid = conditions.audienceRestrictions.contains(where: { restriction in
            restriction.audience == expectedAudience
        })
        
        return isTimeValid && isAudienceValid
    }


    private func extractAssertion(xmlDoc: XMLIndexer) -> SAMLAssertion? {
        let assertion = xmlDoc["samlp:Response"]["saml:Assertion"]
        
        let id = assertion.element?.attribute(by: "ID")?.text ?? ""
        let issueInstant = assertion.element?.attribute(by: "IssueInstant")?.text ?? ""
        let issuer = assertion["saml:Issuer"].element?.text ?? ""
        
        let subjectElement = assertion["saml:Subject"]
        let nameID = subjectElement["saml:NameID"].element?.text ?? ""
        let confirmationElement = subjectElement["saml:SubjectConfirmation"]
        let method = confirmationElement.element?.attribute(by: "Method")?.text ?? ""
        
        let confirmationDataElement = confirmationElement["saml:SubjectConfirmationData"]
        let notBefore = ISO8601DateFormatter().date(from: confirmationDataElement.element?.attribute(by: "NotBefore")?.text ?? "") ?? Date()
        let notOnOrAfter = ISO8601DateFormatter().date(from: confirmationDataElement.element?.attribute(by: "NotOnOrAfter")?.text ?? "") ?? Date()
        let recipient = confirmationDataElement.element?.attribute(by: "Recipient")?.text ?? ""
        let inResponseTo = confirmationDataElement.element?.attribute(by: "InResponseTo")?.text ?? ""
        
        let confirmationData = SAMLConfirmationData(notBefore: notBefore, notOnOrAfter: notOnOrAfter, recipient: recipient, inResponseTo: inResponseTo)
        let confirmation = SAMLSubjectConfirmation(method: method, confirmationData: confirmationData)
        
        let subject = SAMLSubject(nameID: nameID, confirmation: confirmation)
        
        let authnStatementNode = assertion["saml:AuthnStatement"].element
        let authnInstant = authnStatementNode?.attribute(by: "AuthnInstant")?.text ?? ""
        let sessionIndex = authnStatementNode?.attribute(by: "SessionIndex")?.text
        let subjectLocality = assertion["saml:SubjectLocality"].element?.attribute(by: "Address")?.text
        
        let authnContextNode = assertion["saml:AuthnContext"]
        let classRef = assertion["saml:AuthenticatingAuthority"].element?.text ?? ""
        let authnContextClassRef = assertion["saml:AuthnContextClassRef"].element?.text ?? ""
        
        let authnContext = SAMLAuthnContext(classRef: classRef, authnContextClassRef: authnContextClassRef)
        let authnStatement = SAMLAuthnStatement(
            authnInstant: authnInstant,
            sessionIndex: sessionIndex,
            authnContext: authnContext,
            subjectLocality: subjectLocality
        )
        
        let attributes = assertion["saml:AttributeStatement"]["saml:Attribute"]
            .all
            .compactMap { elem -> (String, String)? in
                guard let attributeName = elem.element?.attribute(by: "Name")?.text,
                      let attributeValue = elem["saml:AttributeValue"].element?.text else {
                    return nil
                }
                return (attributeName, attributeValue)
            }.reduce(into: [String: String]()) { dict, pair in
                dict[pair.0] = pair.1
            }
        
        if !issuer.isEmpty && !nameID.isEmpty {
            return SAMLAssertion(
                id: id,
                issuer: issuer,
                issueInstant: issueInstant,
                subject: subject,
                authnStatement: authnStatement,
                attributes: attributes
            )
        } else {
            print("Failed to parse critical elements from SAML Response")
            return nil
        }
    }
}
