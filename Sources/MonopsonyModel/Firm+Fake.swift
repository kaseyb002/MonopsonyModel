import Foundation

extension Firm {
    public static func fake(
        id: FirmID = 1,
        name: String = "TestCorp",
        industry: Industry = .retail,
        acquisitionCost: Int = 100,
        wagePremiums: [Int] = [6, 30, 90, 270, 400, 550],
        departmentCost: Int = 50,
        campusCost: Int = 50,
        frozenValue: Int = 50,
        unfreezeExtra: Int = 5,
        controllingCompany: PlayerID? = nil,
        departments: Int = 0,
        hasCampus: Bool = false,
        isFrozen: Bool = false
    ) -> Firm {
        Firm(
            id: id,
            name: name,
            industry: industry,
            acquisitionCost: acquisitionCost,
            wagePremiums: wagePremiums,
            departmentCost: departmentCost,
            campusCost: campusCost,
            frozenValue: frozenValue,
            unfreezeExtra: unfreezeExtra,
            controllingCompany: controllingCompany,
            departments: departments,
            hasCampus: hasCampus,
            isFrozen: isFrozen
        )
    }
}
