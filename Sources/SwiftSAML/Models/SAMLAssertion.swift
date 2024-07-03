import Foundation

struct SAMLAssertion {
    var id: String
    var issuer: String
    var issueInstant: String
    var subject: SAMLSubject
    var conditions: SAMLConditions?
    var authnStatement: SAMLAuthnStatement
    var attributes: [String: String]
    // Add more as needed
}
