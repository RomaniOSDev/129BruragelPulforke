//
//  AppExternalLink.swift
//  129BruragelPulforke
//

import Foundation

enum AppExternalLink {
    case privacyPolicy
    case termsOfUse

    var url: URL? {
        switch self {
        case .privacyPolicy:
            URL(string: "https://example.com/privacy-policy")
        case .termsOfUse:
            URL(string: "https://example.com/terms")
        }
    }
}
