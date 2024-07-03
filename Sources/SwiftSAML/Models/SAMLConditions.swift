import Foundation

struct SAMLConditions {
    var notBefore: Date
    var notOnOrAfter: Date
    var audienceRestrictions: [SAMLAudienceRestriction]
}
