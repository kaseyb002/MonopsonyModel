import Foundation

public enum Industry: String, Equatable, Codable, Sendable, CaseIterable {
    case fastFood
    case retail
    case warehousing
    case callCenters
    case gigPlatforms
    case manufacturing
    case healthcare
    case bigTech
    case staffingAgency
    case laborPlatform

    public var displayableName: String {
        switch self {
        case .fastFood: "Fast Food"
        case .retail: "Retail"
        case .warehousing: "Warehousing"
        case .callCenters: "Call Centers"
        case .gigPlatforms: "Gig Platforms"
        case .manufacturing: "Manufacturing"
        case .healthcare: "Healthcare"
        case .bigTech: "Big Tech"
        case .staffingAgency: "Staffing Agency"
        case .laborPlatform: "Labor Platform"
        }
    }

    public var isBuildable: Bool {
        switch self {
        case .staffingAgency, .laborPlatform: false
        default: true
        }
    }
}
