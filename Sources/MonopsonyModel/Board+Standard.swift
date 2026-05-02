import Foundation

extension Board {
    public static func standard() -> Board {
        Board(
            spaces: standardSpaces,
            firms: standardFirms,
            marketShockDeck: standardMarketShockCards.shuffled(),
            laborBoardDeck: standardLaborBoardCards.shuffled()
        )
    }

    public static func standardCooked() -> Board {
        Board(
            spaces: standardSpaces,
            firms: standardFirms,
            marketShockDeck: standardMarketShockCards,
            laborBoardDeck: standardLaborBoardCards
        )
    }

    // MARK: - Board Spaces (40 spaces, Monopoly layout)

    static var standardSpaces: [BoardSpace] {
        [
            .payroll,                   // 0: GO
            .firm(1),                   // 1: Fast Food 1
            .laborBoard,                // 2: Community Chest
            .firm(2),                   // 3: Fast Food 2
            .payrollTax,                // 4: Income Tax
            .staffingAgency(23),        // 5: Railroad 1
            .firm(3),                   // 6: Retail 1
            .marketShock,               // 7: Chance
            .firm(4),                   // 8: Retail 2
            .firm(5),                   // 9: Retail 3
            .underObservation,          // 10: Just Visiting / Jail
            .firm(6),                   // 11: Warehousing 1
            .laborPlatform(27),         // 12: Utility 1
            .firm(7),                   // 13: Warehousing 2
            .firm(8),                   // 14: Warehousing 3
            .staffingAgency(24),        // 15: Railroad 2
            .firm(9),                   // 16: Call Centers 1
            .laborBoard,                // 17: Community Chest
            .firm(10),                  // 18: Call Centers 2
            .firm(11),                  // 19: Call Centers 3
            .publicGrant,               // 20: Free Parking
            .firm(12),                  // 21: Gig Platforms 1
            .marketShock,               // 22: Chance
            .firm(13),                  // 23: Gig Platforms 2
            .firm(14),                  // 24: Gig Platforms 3
            .staffingAgency(25),        // 25: Railroad 3
            .firm(15),                  // 26: Manufacturing 1
            .firm(16),                  // 27: Manufacturing 2
            .laborPlatform(28),         // 28: Utility 2
            .firm(17),                  // 29: Manufacturing 3
            .antitrustProbe,            // 30: Go To Jail
            .firm(18),                  // 31: Healthcare 1
            .firm(19),                  // 32: Healthcare 2
            .laborBoard,                // 33: Community Chest
            .firm(20),                  // 34: Healthcare 3
            .staffingAgency(26),        // 35: Railroad 4
            .marketShock,               // 36: Chance
            .firm(21),                  // 37: Big Tech 1
            .complianceFine,            // 38: Luxury Tax
            .firm(22),                  // 39: Big Tech 2
        ]
    }

    // MARK: - Firms

    // swiftlint:disable function_body_length
    static var standardFirms: [Firm] {
        [
            // Fast Food (2 firms) — cheapest
            Firm(id: 1, name: "QuickBite", industry: .fastFood,
                 acquisitionCost: 60, wagePremiums: [2, 10, 30, 90, 160, 250],
                 departmentCost: 50, campusCost: 50, frozenValue: 30, unfreezeExtra: 3),
            Firm(id: 2, name: "FryChain", industry: .fastFood,
                 acquisitionCost: 60, wagePremiums: [4, 20, 60, 180, 320, 450],
                 departmentCost: 50, campusCost: 50, frozenValue: 30, unfreezeExtra: 3),

            // Retail (3 firms)
            Firm(id: 3, name: "MegaMart", industry: .retail,
                 acquisitionCost: 100, wagePremiums: [6, 30, 90, 270, 400, 550],
                 departmentCost: 50, campusCost: 50, frozenValue: 50, unfreezeExtra: 5),
            Firm(id: 4, name: "ValuePlus", industry: .retail,
                 acquisitionCost: 100, wagePremiums: [6, 30, 90, 270, 400, 550],
                 departmentCost: 50, campusCost: 50, frozenValue: 50, unfreezeExtra: 5),
            Firm(id: 5, name: "ShopNow", industry: .retail,
                 acquisitionCost: 120, wagePremiums: [8, 40, 100, 300, 450, 600],
                 departmentCost: 50, campusCost: 50, frozenValue: 60, unfreezeExtra: 6),

            // Warehousing (3 firms)
            Firm(id: 6, name: "SwiftShip", industry: .warehousing,
                 acquisitionCost: 140, wagePremiums: [10, 50, 150, 450, 625, 750],
                 departmentCost: 100, campusCost: 100, frozenValue: 70, unfreezeExtra: 7),
            Firm(id: 7, name: "BoxHold", industry: .warehousing,
                 acquisitionCost: 140, wagePremiums: [10, 50, 150, 450, 625, 750],
                 departmentCost: 100, campusCost: 100, frozenValue: 70, unfreezeExtra: 7),
            Firm(id: 8, name: "FloorStack", industry: .warehousing,
                 acquisitionCost: 160, wagePremiums: [12, 60, 180, 500, 700, 900],
                 departmentCost: 100, campusCost: 100, frozenValue: 80, unfreezeExtra: 8),

            // Call Centers (3 firms)
            Firm(id: 9, name: "DialDirect", industry: .callCenters,
                 acquisitionCost: 180, wagePremiums: [14, 70, 200, 550, 750, 950],
                 departmentCost: 100, campusCost: 100, frozenValue: 90, unfreezeExtra: 9),
            Firm(id: 10, name: "PhonePulse", industry: .callCenters,
                 acquisitionCost: 180, wagePremiums: [14, 70, 200, 550, 750, 950],
                 departmentCost: 100, campusCost: 100, frozenValue: 90, unfreezeExtra: 9),
            Firm(id: 11, name: "VoiceLink", industry: .callCenters,
                 acquisitionCost: 200, wagePremiums: [16, 80, 220, 600, 800, 1000],
                 departmentCost: 100, campusCost: 100, frozenValue: 100, unfreezeExtra: 10),

            // Gig Platforms (3 firms)
            Firm(id: 12, name: "GigSnap", industry: .gigPlatforms,
                 acquisitionCost: 220, wagePremiums: [18, 90, 250, 700, 875, 1050],
                 departmentCost: 150, campusCost: 150, frozenValue: 110, unfreezeExtra: 11),
            Firm(id: 13, name: "FlexHire", industry: .gigPlatforms,
                 acquisitionCost: 220, wagePremiums: [18, 90, 250, 700, 875, 1050],
                 departmentCost: 150, campusCost: 150, frozenValue: 110, unfreezeExtra: 11),
            Firm(id: 14, name: "TaskDash", industry: .gigPlatforms,
                 acquisitionCost: 240, wagePremiums: [20, 100, 300, 750, 925, 1100],
                 departmentCost: 150, campusCost: 150, frozenValue: 120, unfreezeExtra: 12),

            // Manufacturing (3 firms)
            Firm(id: 15, name: "IronWorks", industry: .manufacturing,
                 acquisitionCost: 260, wagePremiums: [22, 110, 330, 800, 975, 1150],
                 departmentCost: 150, campusCost: 150, frozenValue: 130, unfreezeExtra: 13),
            Firm(id: 16, name: "SteelVault", industry: .manufacturing,
                 acquisitionCost: 260, wagePremiums: [22, 110, 330, 800, 975, 1150],
                 departmentCost: 150, campusCost: 150, frozenValue: 130, unfreezeExtra: 13),
            Firm(id: 17, name: "PressLine", industry: .manufacturing,
                 acquisitionCost: 280, wagePremiums: [24, 120, 360, 850, 1025, 1200],
                 departmentCost: 150, campusCost: 150, frozenValue: 140, unfreezeExtra: 14),

            // Healthcare (3 firms)
            Firm(id: 18, name: "MedScope", industry: .healthcare,
                 acquisitionCost: 300, wagePremiums: [26, 130, 390, 900, 1100, 1275],
                 departmentCost: 200, campusCost: 200, frozenValue: 150, unfreezeExtra: 15),
            Firm(id: 19, name: "CareAxis", industry: .healthcare,
                 acquisitionCost: 300, wagePremiums: [26, 130, 390, 900, 1100, 1275],
                 departmentCost: 200, campusCost: 200, frozenValue: 150, unfreezeExtra: 15),
            Firm(id: 20, name: "VitalPath", industry: .healthcare,
                 acquisitionCost: 320, wagePremiums: [28, 150, 450, 1000, 1200, 1400],
                 departmentCost: 200, campusCost: 200, frozenValue: 160, unfreezeExtra: 16),

            // Big Tech (2 firms) — most expensive
            Firm(id: 21, name: "OmniSearch", industry: .bigTech,
                 acquisitionCost: 350, wagePremiums: [35, 175, 500, 1100, 1300, 1500],
                 departmentCost: 200, campusCost: 200, frozenValue: 175, unfreezeExtra: 18),
            Firm(id: 22, name: "Nimbus Cloud", industry: .bigTech,
                 acquisitionCost: 400, wagePremiums: [50, 200, 600, 1400, 1700, 2000],
                 departmentCost: 200, campusCost: 200, frozenValue: 200, unfreezeExtra: 20),

            // Staffing Agencies (equivalent to railroads)
            Firm(id: 23, name: "Campus Recruiting", industry: .staffingAgency,
                 acquisitionCost: 200, wagePremiums: [25, 50, 100, 200, 0, 0],
                 departmentCost: 0, campusCost: 0, frozenValue: 100, unfreezeExtra: 10),
            Firm(id: 24, name: "Temp Staffing", industry: .staffingAgency,
                 acquisitionCost: 200, wagePremiums: [25, 50, 100, 200, 0, 0],
                 departmentCost: 0, campusCost: 0, frozenValue: 100, unfreezeExtra: 10),
            Firm(id: 25, name: "Executive Search", industry: .staffingAgency,
                 acquisitionCost: 200, wagePremiums: [25, 50, 100, 200, 0, 0],
                 departmentCost: 0, campusCost: 0, frozenValue: 100, unfreezeExtra: 10),
            Firm(id: 26, name: "Visa Sponsorship", industry: .staffingAgency,
                 acquisitionCost: 200, wagePremiums: [25, 50, 100, 200, 0, 0],
                 departmentCost: 0, campusCost: 0, frozenValue: 100, unfreezeExtra: 10),

            // Labor Platforms (equivalent to utilities)
            Firm(id: 27, name: "Job Platform", industry: .laborPlatform,
                 acquisitionCost: 150, wagePremiums: [0, 0, 0, 0, 0, 0],
                 departmentCost: 0, campusCost: 0, frozenValue: 75, unfreezeExtra: 8),
            Firm(id: 28, name: "Payroll Network", industry: .laborPlatform,
                 acquisitionCost: 150, wagePremiums: [0, 0, 0, 0, 0, 0],
                 departmentCost: 0, campusCost: 0, frozenValue: 75, unfreezeExtra: 8),
        ]
    }
    // swiftlint:enable function_body_length

    // MARK: - Staffing Agency / Labor Platform IDs

    public static let staffingAgencyIDs: Set<FirmID> = [23, 24, 25, 26]
    public static let laborPlatformIDs: Set<FirmID> = [27, 28]

    public func staffingAgencyCount(for playerID: PlayerID) -> Int {
        Self.staffingAgencyIDs.filter { id in
            firms.first(where: { $0.id == id })?.controllingCompany == playerID
        }.count
    }

    public func laborPlatformCount(for playerID: PlayerID) -> Int {
        Self.laborPlatformIDs.filter { id in
            firms.first(where: { $0.id == id })?.controllingCompany == playerID
        }.count
    }

    public func staffingAgencyWagePremium(ownedCount: Int) -> Int {
        switch ownedCount {
        case 1: 25
        case 2: 50
        case 3: 100
        case 4: 200
        default: 0
        }
    }

    public func laborPlatformWagePremium(ownedCount: Int, diceRoll: Int) -> Int {
        switch ownedCount {
        case 1: diceRoll * 4
        case 2: diceRoll * 10
        default: 0
        }
    }

    // MARK: - Market Shock Cards

    static var standardMarketShockCards: [MarketShockCard] {
        [
            MarketShockCard(id: 1, title: "VC Funding Boom",
                            description: "A venture capital boom floods your industry. Collect $150 from Capital Market.",
                            effect: .gainCapital(150)),
            MarketShockCard(id: 2, title: "Automation Breakthrough",
                            description: "Advance to Payroll. Collect $200 if you pass.",
                            effect: .moveToSpace(0)),
            MarketShockCard(id: 3, title: "Competitor Poaching",
                            description: "A rival poaches your top talent. Pay $50.",
                            effect: .loseCapital(50)),
            MarketShockCard(id: 4, title: "Viral Recruiting Campaign",
                            description: "Your employer brand goes viral. Collect $100.",
                            effect: .gainCapital(100)),
            MarketShockCard(id: 5, title: "Antitrust Probe",
                            description: "Regulators launch an investigation. Go directly to Investigation.",
                            effect: .antitrustProbe),
            MarketShockCard(id: 6, title: "Industry Downturn",
                            description: "Pay each player $50 in severance packages.",
                            effect: .payEachPlayer(50)),
            MarketShockCard(id: 7, title: "Platform Outage",
                            description: "Major systems failure. Pay $100 in emergency repairs.",
                            effect: .loseCapital(100)),
            MarketShockCard(id: 8, title: "Worker Migration",
                            description: "Advance 3 spaces.",
                            effect: .moveSpaces(3)),
            MarketShockCard(id: 9, title: "Talent Shortage",
                            description: "Skilled workers are scarce. Collect $200.",
                            effect: .gainCapital(200)),
            MarketShockCard(id: 10, title: "Settlement Agreement",
                            description: "You secured a settlement agreement. Keep this card until needed.",
                            effect: .settlementAgreement),
            MarketShockCard(id: 11, title: "Regulatory Review",
                            description: "Go back 3 spaces.",
                            effect: .moveSpaces(-3)),
            MarketShockCard(id: 12, title: "Market Expansion",
                            description: "Advance to the nearest Staffing Agency. If unowned, you may acquire it.",
                            effect: .gainCapital(25)),
            MarketShockCard(id: 13, title: "Hostile Takeover Attempt",
                            description: "Pay repair costs: $25 per department, $100 per corporate campus.",
                            effect: .repairCost(perDepartment: 25, perCampus: 100)),
            MarketShockCard(id: 14, title: "Government Contract",
                            description: "Awarded a lucrative contract. Collect $50.",
                            effect: .gainCapital(50)),
            MarketShockCard(id: 15, title: "Stock Buyback",
                            description: "Market confidence soars. Collect $75.",
                            effect: .gainCapital(75)),
            MarketShockCard(id: 16, title: "Supply Chain Disruption",
                            description: "Pay $75 for emergency logistics.",
                            effect: .loseCapital(75)),
        ]
    }

    // MARK: - Labor Board Cards

    static var standardLaborBoardCards: [LaborBoardCard] {
        [
            LaborBoardCard(id: 1, title: "Training Tax Credit",
                           description: "Government training subsidy. Collect $200.",
                           effect: .gainCapital(200)),
            LaborBoardCard(id: 2, title: "Wage Theft Settlement",
                           description: "Forced to pay back wages. Pay $100.",
                           effect: .loseCapital(100)),
            LaborBoardCard(id: 3, title: "Apprenticeship Grant",
                           description: "Receive a workforce development grant. Collect $100.",
                           effect: .gainCapital(100)),
            LaborBoardCard(id: 4, title: "Union Drive",
                           description: "Workers organize. Pay $50 for negotiations.",
                           effect: .loseCapital(50)),
            LaborBoardCard(id: 5, title: "Compliance Audit",
                           description: "Auditors find irregularities. Pay $150.",
                           effect: .loseCapital(150)),
            LaborBoardCard(id: 6, title: "Worker Safety Fine",
                           description: "Pay repair costs: $40 per department, $115 per corporate campus.",
                           effect: .repairCost(perDepartment: 40, perCampus: 115)),
            LaborBoardCard(id: 7, title: "Public Subsidy",
                           description: "Receive a public subsidy. Collect $50.",
                           effect: .gainCapital(50)),
            LaborBoardCard(id: 8, title: "Backpay Order",
                           description: "Ordered to pay backpay. Pay $75.",
                           effect: .loseCapital(75)),
            LaborBoardCard(id: 9, title: "Antitrust Probe",
                           description: "Labor board refers you for investigation. Go directly to Investigation.",
                           effect: .antitrustProbe),
            LaborBoardCard(id: 10, title: "Settlement Agreement",
                           description: "You secured a settlement agreement. Keep this card until needed.",
                           effect: .settlementAgreement),
            LaborBoardCard(id: 11, title: "Workforce Innovation Award",
                           description: "Recognized for innovative practices. Collect $25.",
                           effect: .gainCapital(25)),
            LaborBoardCard(id: 12, title: "Industry Conference",
                           description: "Networking pays off. Collect from each player $10.",
                           effect: .collectFromEachPlayer(10)),
            LaborBoardCard(id: 13, title: "Minimum Wage Increase",
                           description: "Pay $25 per department you operate.",
                           effect: .repairCost(perDepartment: 25, perCampus: 0)),
            LaborBoardCard(id: 14, title: "Advance to Payroll",
                           description: "Advance to Payroll. Collect $200.",
                           effect: .moveToSpace(0)),
            LaborBoardCard(id: 15, title: "Insurance Payout",
                           description: "Collect $100 from insurance.",
                           effect: .gainCapital(100)),
            LaborBoardCard(id: 16, title: "Recruiting Bonus",
                           description: "Successful hiring round. Collect $20.",
                           effect: .gainCapital(20)),
        ]
    }
}
