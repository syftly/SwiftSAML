import Foundation

struct SAMLConfirmationData {
    var notBefore: Date
    var notOnOrAfter: Date
    var recipient: String
    var inResponseTo: String
}
