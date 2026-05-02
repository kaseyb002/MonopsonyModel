import Foundation

public typealias FirmID = Int

public struct Firm: Equatable, Codable, Sendable, Identifiable {
    public let id: FirmID
    public let name: String
    public let industry: Industry
    public let acquisitionCost: Int
    public let wagePremiums: [Int]
    public let departmentCost: Int
    public let campusCost: Int
    public let frozenValue: Int
    public let unfreezeExtra: Int
    public var controllingCompany: PlayerID?
    public var departments: Int
    public var hasCampus: Bool
    public var isFrozen: Bool

    public init(
        id: FirmID,
        name: String,
        industry: Industry,
        acquisitionCost: Int,
        wagePremiums: [Int],
        departmentCost: Int,
        campusCost: Int,
        frozenValue: Int,
        unfreezeExtra: Int,
        controllingCompany: PlayerID? = nil,
        departments: Int = 0,
        hasCampus: Bool = false,
        isFrozen: Bool = false
    ) {
        self.id = id
        self.name = name
        self.industry = industry
        self.acquisitionCost = acquisitionCost
        self.wagePremiums = wagePremiums
        self.departmentCost = departmentCost
        self.campusCost = campusCost
        self.frozenValue = frozenValue
        self.unfreezeExtra = unfreezeExtra
        self.controllingCompany = controllingCompany
        self.departments = departments
        self.hasCampus = hasCampus
        self.isFrozen = isFrozen
    }

    public static let maxDepartments: Int = 4

    public var currentWagePremium: Int {
        if isFrozen { return 0 }
        if hasCampus { return wagePremiums[5] }
        return wagePremiums[departments]
    }

    public var totalInvestment: Int {
        acquisitionCost + (departments * departmentCost) + (hasCampus ? campusCost : 0)
    }
}
