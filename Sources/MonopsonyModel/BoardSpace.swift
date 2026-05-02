import Foundation

public typealias BoardSpaceID = Int

public enum BoardSpace: Equatable, Codable, Sendable {
    case payroll
    case firm(FirmID)
    case staffingAgency(FirmID)
    case laborPlatform(FirmID)
    case payrollTax
    case complianceFine
    case marketShock
    case laborBoard
    case antitrustProbe
    case underObservation
    case publicGrant

    public var displayableName: String {
        switch self {
        case .payroll: "Payroll"
        case .firm: "Firm"
        case .staffingAgency: "Staffing Agency"
        case .laborPlatform: "Labor Platform"
        case .payrollTax: "Payroll Tax"
        case .complianceFine: "Compliance Fine"
        case .marketShock: "Market Shock"
        case .laborBoard: "Labor Board"
        case .antitrustProbe: "Antitrust Probe"
        case .underObservation: "Under Observation"
        case .publicGrant: "Public Grant"
        }
    }
}
