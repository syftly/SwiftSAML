import Foundation

struct SAMLAuthnStatement {
    var authnInstant: String
    var sessionIndex: String?
    var authnContext: SAMLAuthnContext
    var subjectLocality: String?
}
