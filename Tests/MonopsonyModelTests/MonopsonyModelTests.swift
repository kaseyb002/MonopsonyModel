import Foundation
import Testing
@testable import MonopsonyModel

// MARK: - Test Helpers

private func makePlayers() -> [Player] {
    [
        Player(id: "alice", name: "Alice", capital: 1500, companyName: "Acme Holdings"),
        Player(id: "bob", name: "Bob", capital: 1500, companyName: "Apex Industries"),
    ]
}

private func makeReadyRound() throws -> Round {
    try Round(
        board: .standardCooked(),
        players: makePlayers()
    )
}

// MARK: - Initialization Tests

@Test
func initializeRound() throws {
    let round: Round = try makeReadyRound()

    #expect(round.playerStates.count == 2)
    #expect(round.playerStates[0].player.capital == 1500)
    #expect(round.playerStates[1].player.capital == 1500)
    #expect(round.playerStates[0].position == 0)
    #expect(round.playerStates[1].position == 0)
    #expect(round.board.spaceCount == 40)

    if case .preRoll(let id) = round.state {
        #expect(id == "alice")
    } else {
        Issue.record("Expected preRoll state")
    }
}

@Test
func initializeRoundFailsWithTooFewPlayers() {
    #expect(throws: MonopsonyModelError.notEnoughPlayers) {
        try Round(players: [Player(id: "solo", name: "Solo", capital: 1500, companyName: "Solo Corp")])
    }
}

@Test
func initializeRoundFailsWithTooManyPlayers() {
    let players: [Player] = (1...9).map {
        Player(id: "p\($0)", name: "Player \($0)", capital: 1500, companyName: "Corp \($0)")
    }
    #expect(throws: MonopsonyModelError.tooManyPlayers) {
        try Round(players: players)
    }
}

// MARK: - Dice Roll Tests

@Test
func rollDice() throws {
    var round: Round = try makeReadyRound()

    // Roll to position 6 (firm 3 = MegaMart, unowned). Avoids card spaces.
    try round.rollDice(cookedRoll: .init(die1: 3, die2: 3))

    #expect(round.playerStates[0].position == 6)
    #expect(round.log.count >= 1)
}

@Test
func rollDiceMovesPlayerAndPassesPayroll() throws {
    var round: Round = try makeReadyRound()

    round.playerStates[0].position = 38

    try round.rollDice(cookedRoll: .init(die1: 3, die2: 4))

    #expect(round.playerStates[0].position == 5)
    #expect(round.playerStates[0].player.capital == 1500 + Round.payrollSalary)
}

@Test
func threeDoublesGoToInvestigation() throws {
    var round: Round = try makeReadyRound()

    // Roll doubles three times → antitrust probe
    try round.rollDice(cookedRoll: .init(die1: 1, die2: 1))
    // After doubles, still Alice's turn (doubles = extra turn)
    // But we need to handle the landing first. Let's use a simple test.
    // Position 2 is laborBoard card, which advances or takes capital.
    // Let's set position manually and test the three-doubles rule.
    round.playerStates[0].doublesRolledInRow = 2
    round.state = .preRoll(playerID: "alice")
    round.currentPlayerIndex = 0

    try round.rollDice(cookedRoll: .init(die1: 3, die2: 3))

    #expect(round.playerStates[0].position == 10)
    #expect(round.playerStates[0].isInInvestigation == true)
}

// MARK: - Firm Acquisition Tests

@Test
func acquireFirm() throws {
    var round: Round = try makeReadyRound()

    // Roll to land on firm at position 1 (QuickBite, cost 60)
    try round.rollDice(cookedRoll: .init(die1: 1, die2: 0))
    // That's invalid, use valid dice. Smallest move to position 1 is die1=1, die2=0 but min is 1
    // Let's just position manually.

    round.playerStates[0].position = 0
    round.state = .preRoll(playerID: "alice")
    round.currentPlayerIndex = 0

    // Roll 1 (can't with 2 dice... minimum is 2). Let's use position 3 which is firm 2 (FryChain, cost 60)
    try round.rollDice(cookedRoll: .init(die1: 1, die2: 2))
    // Position 3 = firm(2) = FryChain

    if case .buyDecision(let id, let firmID) = round.state {
        #expect(id == "alice")
        #expect(firmID == 2)

        try round.acquireFirm(playerID: "alice")

        let firm: Firm? = round.board.firm(byID: 2)
        #expect(firm?.controllingCompany == "alice")
        #expect(round.playerStates[0].player.capital == 1500 - 60)
    } else {
        Issue.record("Expected buyDecision state, got \(round.state)")
    }
}

@Test
func declineFirm() throws {
    var round: Round = try makeReadyRound()

    try round.rollDice(cookedRoll: .init(die1: 1, die2: 2))

    if case .buyDecision(let id, _) = round.state {
        #expect(id == "alice")
        try round.declineFirm(playerID: "alice")
        #expect(round.playerStates[0].player.capital == 1500)
    } else {
        Issue.record("Expected buyDecision state")
    }
}

@Test
func acquireFirmNotEnoughCapital() throws {
    var round: Round = try makeReadyRound()
    round.playerStates[0].player.capital = 10

    try round.rollDice(cookedRoll: .init(die1: 1, die2: 2))

    // Should skip buy decision since capital < cost
    if case .buyDecision = round.state {
        Issue.record("Should not offer buy decision when insufficient capital")
    }
}

// MARK: - Wage Premium (Rent) Tests

@Test
func payWagePremium() throws {
    var round: Round = try makeReadyRound()

    // Alice owns firm 2 (FryChain, position 3)
    round.board.firms[1].controllingCompany = "alice"

    // Bob lands on firm 2
    round.playerStates[1].position = 0
    round.currentPlayerIndex = 1
    round.state = .preRoll(playerID: "bob")

    try round.rollDice(cookedRoll: .init(die1: 1, die2: 2))

    // Bob should have paid wage premium to Alice
    let premium: Int = round.board.firms[1].wagePremiums[0]
    #expect(round.playerStates[1].player.capital == 1500 - premium)
    #expect(round.playerStates[0].player.capital == 1500 + premium)
}

@Test
func noWagePremiumOnFrozenFirm() throws {
    var round: Round = try makeReadyRound()

    round.board.firms[1].controllingCompany = "alice"
    round.board.firms[1].isFrozen = true

    round.playerStates[1].position = 0
    round.currentPlayerIndex = 1
    round.state = .preRoll(playerID: "bob")

    try round.rollDice(cookedRoll: .init(die1: 1, die2: 2))

    #expect(round.playerStates[1].player.capital == 1500)
    #expect(round.playerStates[0].player.capital == 1500)
}

// MARK: - Building Tests

@Test
func buildDepartment() throws {
    var round: Round = try makeReadyRound()

    // Give Alice both fast food firms (industry control required)
    round.board.firms[0].controllingCompany = "alice" // QuickBite
    round.board.firms[1].controllingCompany = "alice" // FryChain

    round.state = .awaitingAction(playerID: "alice")

    try round.buildDepartment(playerID: "alice", firmID: 1)

    let firm: Firm? = round.board.firm(byID: 1)
    #expect(firm?.departments == 1)
    #expect(round.playerStates[0].player.capital == 1500 - 50)
}

@Test
func cannotBuildWithoutIndustryControl() throws {
    var round: Round = try makeReadyRound()

    // Alice only owns 1 of 3 retail firms
    round.board.firms[2].controllingCompany = "alice" // MegaMart (retail)

    round.state = .awaitingAction(playerID: "alice")

    #expect(throws: MonopsonyModelError.cannotBuildWithoutIndustryControl) {
        try round.buildDepartment(playerID: "alice", firmID: 3)
    }
}

@Test
func mustBuildEvenly() throws {
    var round: Round = try makeReadyRound()

    round.board.firms[0].controllingCompany = "alice"
    round.board.firms[1].controllingCompany = "alice"
    round.board.firms[0].departments = 1 // QuickBite has 1

    round.state = .awaitingAction(playerID: "alice")

    // Can't build on QuickBite (1 dept) when FryChain has 0
    #expect(throws: MonopsonyModelError.mustBuildEvenly) {
        try round.buildDepartment(playerID: "alice", firmID: 1)
    }

    // Can build on FryChain (0 dept) to even out
    try round.buildDepartment(playerID: "alice", firmID: 2)
    #expect(round.board.firm(byID: 2)?.departments == 1)
}

// MARK: - Freeze / Resume Hiring Tests

@Test
func freezeHiring() throws {
    var round: Round = try makeReadyRound()
    round.board.firms[0].controllingCompany = "alice"

    round.state = .awaitingAction(playerID: "alice")

    try round.freezeHiring(playerID: "alice", firmID: 1)

    #expect(round.board.firm(byID: 1)?.isFrozen == true)
    #expect(round.playerStates[0].player.capital == 1500 + 30) // frozenValue = 30
}

@Test
func resumeHiring() throws {
    var round: Round = try makeReadyRound()
    round.board.firms[0].controllingCompany = "alice"
    round.board.firms[0].isFrozen = true

    round.state = .awaitingAction(playerID: "alice")

    try round.resumeHiring(playerID: "alice", firmID: 1)

    #expect(round.board.firm(byID: 1)?.isFrozen == false)
    #expect(round.playerStates[0].player.capital == 1500 - 33) // frozenValue(30) + unfreezeExtra(3) = 33
}

@Test
func cannotFreezeWithDepartments() throws {
    var round: Round = try makeReadyRound()
    round.board.firms[0].controllingCompany = "alice"
    round.board.firms[0].departments = 1
    round.board.firms[1].controllingCompany = "alice"

    round.state = .awaitingAction(playerID: "alice")

    #expect(throws: MonopsonyModelError.cannotFreezeWithDepartments) {
        try round.freezeHiring(playerID: "alice", firmID: 1)
    }
}

// MARK: - Investigation Tests

@Test
func investigationEscapeByRollingDoubles() throws {
    var round: Round = try makeReadyRound()
    round.playerStates[0].isInInvestigation = true
    round.playerStates[0].position = 10
    round.state = .preRoll(playerID: "alice")

    try round.rollDice(cookedRoll: .init(die1: 3, die2: 3))

    #expect(round.playerStates[0].isInInvestigation == false)
    #expect(round.playerStates[0].position != 10)
}

@Test
func investigationPayBail() throws {
    var round: Round = try makeReadyRound()
    round.playerStates[0].isInInvestigation = true
    round.playerStates[0].position = 10
    round.state = .preRoll(playerID: "alice")

    try round.payBail(playerID: "alice")

    #expect(round.playerStates[0].isInInvestigation == false)
    #expect(round.playerStates[0].player.capital == 1500 - Round.investigationBailCost)
}

@Test
func investigationUseSettlement() throws {
    var round: Round = try makeReadyRound()
    round.playerStates[0].isInInvestigation = true
    round.playerStates[0].settlementAgreements = 1
    round.playerStates[0].position = 10
    round.state = .preRoll(playerID: "alice")

    try round.useSettlementAgreement(playerID: "alice")

    #expect(round.playerStates[0].isInInvestigation == false)
    #expect(round.playerStates[0].settlementAgreements == 0)
    #expect(round.playerStates[0].player.capital == 1500)
}

// MARK: - Tax Tests

@Test
func payrollTax() throws {
    var round: Round = try makeReadyRound()
    // Position 4 is payroll tax
    round.playerStates[0].position = 0
    round.state = .preRoll(playerID: "alice")

    try round.rollDice(cookedRoll: .init(die1: 2, die2: 2))
    // Position 4 = payrollTax

    #expect(round.playerStates[0].player.capital == 1500 - Round.payrollTaxAmount)
}

@Test
func complianceFine() throws {
    var round: Round = try makeReadyRound()
    round.playerStates[0].position = 35
    round.state = .preRoll(playerID: "alice")

    try round.rollDice(cookedRoll: .init(die1: 2, die2: 1))
    // Position 38 = complianceFine

    #expect(round.playerStates[0].player.capital == 1500 - Round.complianceFineAmount)
}

// MARK: - Bankruptcy Tests

@Test
func bankruptcy() throws {
    var round: Round = try makeReadyRound()
    round.playerStates[0].player.capital = 5

    // Land on payroll tax (position 4) which costs 200
    round.playerStates[0].position = 0
    round.state = .preRoll(playerID: "alice")

    try round.rollDice(cookedRoll: .init(die1: 2, die2: 2))

    #expect(round.playerStates[0].isBankrupt == true)
    #expect(round.isComplete == true)
}

// MARK: - Antitrust Probe Space Tests

@Test
func landingOnAntitrustProbe() throws {
    var round: Round = try makeReadyRound()
    // Position 30 is antitrustProbe. Put player near it.
    round.playerStates[0].position = 25
    round.state = .preRoll(playerID: "alice")

    try round.rollDice(cookedRoll: .init(die1: 3, die2: 2))

    #expect(round.playerStates[0].position == 10)
    #expect(round.playerStates[0].isInInvestigation == true)
}

// MARK: - Board Tests

@Test
func standardBoardLayout() {
    let board: Board = .standard()

    #expect(board.spaceCount == 40)
    #expect(board.firms.count == 28)
    #expect(board.marketShockDeck.count == 16)
    #expect(board.laborBoardDeck.count == 16)

    if case .payroll = board.spaces[0] {} else {
        Issue.record("First space should be Payroll")
    }

    if case .antitrustProbe = board.spaces[30] {} else {
        Issue.record("Space 30 should be Antitrust Probe")
    }
}

@Test
func industryControl() {
    var board: Board = .standardCooked()

    #expect(!board.playerControlsIndustry("alice", industry: .fastFood))

    board.firms[0].controllingCompany = "alice"
    board.firms[1].controllingCompany = "alice"

    #expect(board.playerControlsIndustry("alice", industry: .fastFood))
}

@Test
func staffingAgencyPremium() {
    let board: Board = .standardCooked()
    #expect(board.staffingAgencyWagePremium(ownedCount: 1) == 25)
    #expect(board.staffingAgencyWagePremium(ownedCount: 2) == 50)
    #expect(board.staffingAgencyWagePremium(ownedCount: 3) == 100)
    #expect(board.staffingAgencyWagePremium(ownedCount: 4) == 200)
}

@Test
func laborPlatformPremium() {
    let board: Board = .standardCooked()
    #expect(board.laborPlatformWagePremium(ownedCount: 1, diceRoll: 7) == 28)
    #expect(board.laborPlatformWagePremium(ownedCount: 2, diceRoll: 7) == 70)
}

// MARK: - Firm Tests

@Test
func firmWagePremiums() {
    var firm: Firm = .fake()
    #expect(firm.currentWagePremium == 6)

    firm.departments = 2
    #expect(firm.currentWagePremium == 90)

    firm.isFrozen = true
    #expect(firm.currentWagePremium == 0)
}

// MARK: - Scoring Tests

@Test
func netWorthCalculation() throws {
    var round: Round = try makeReadyRound()
    round.board.firms[0].controllingCompany = "alice"

    let nw: Int = round.netWorth(for: "alice")
    #expect(nw == 1500 + 60) // capital + QuickBite acquisition cost
}

@Test
func rankings() throws {
    var round: Round = try makeReadyRound()
    round.board.firms[0].controllingCompany = "alice"
    round.playerStates[0].player.capital = 2000

    let ranks = round.rankings()
    #expect(ranks[0].player.id == "alice")
    #expect(ranks[0].netWorth > ranks[1].netWorth)
}

// MARK: - Fake Tests

@Test
func fakeFactories() throws {
    let player: Player = .fake()
    #expect(!player.id.isEmpty)

    let ps: PlayerState = .fake()
    #expect(ps.position == 0)

    let firm: Firm = .fake()
    #expect(firm.acquisitionCost == 100)

    let round: Round = try .fake()
    #expect(round.playerStates.count == 2)
}

@Test
func fakeCompletedRound() throws {
    let round: Round = try .fakeCompleted()

    guard case .gameComplete(let winner) = round.state else {
        Issue.record("Expected gameComplete state")
        return
    }

    #expect(round.isComplete)
    #expect(round.ended != nil)
    #expect(winner.id == "p1")
    #expect(round.playerStates.count == 2)
    #expect(round.log.count == 6)

    // Round-trips through Codable
    let data: Data = try JSONEncoder().encode(round)
    let decoded: Round = try JSONDecoder().decode(Round.self, from: data)
    #expect(decoded.isComplete)
    #expect(decoded.playerStates.count == round.playerStates.count)
}

// MARK: - Codable Tests

@Test
func roundCodable() throws {
    let round: Round = try makeReadyRound()

    let data: Data = try JSONEncoder().encode(round)
    let decoded: Round = try JSONDecoder().decode(Round.self, from: data)

    #expect(decoded.id == round.id)
    #expect(decoded.playerStates.count == round.playerStates.count)
    #expect(decoded.board.spaceCount == round.board.spaceCount)
}

// MARK: - AI Engine Tests

@Test
func aiEngineReturnsValidAction() throws {
    var round: Round = try makeReadyRound()
    let engine: AIEngine = AIEngine()

    let action: AIAction = engine.chooseAction(for: round, playerID: "alice")
    #expect(action == .roll)

    try action.apply(to: &round, playerID: "alice")
}

@Test
func aiEngineBuyDecision() throws {
    var round: Round = try makeReadyRound()

    try round.rollDice(cookedRoll: .init(die1: 1, die2: 2))

    if case .buyDecision(let id, _) = round.state {
        let engine: AIEngine = AIEngine(difficulty: .easy)
        let action: AIAction = engine.chooseAction(for: round, playerID: id)
        #expect(action == .acquireFirm || action == .declineFirm)
    }
}

@Test
func aiEngineHandlesInvestigation() throws {
    var round: Round = try makeReadyRound()
    round.playerStates[0].isInInvestigation = true
    round.playerStates[0].settlementAgreements = 1
    round.state = .preRoll(playerID: "alice")

    let engine: AIEngine = AIEngine()
    let action: AIAction = engine.chooseAction(for: round, playerID: "alice")
    #expect(action == .useSettlement)
}

@Test
func aiFullGame() throws {
    var round: Round = try Round(
        board: .standardCooked(),
        players: [
            Player(id: "p1", name: "Alice", capital: 1500, companyName: "Acme"),
            Player(id: "p2", name: "Bob", capital: 1500, companyName: "Apex"),
        ]
    )

    let engine: AIEngine = AIEngine(difficulty: .easy)
    var turnCount: Int = 0
    let maxTurns: Int = 2000

    while !round.isComplete && turnCount < maxTurns {
        guard let playerID = round.currentPlayerID else { break }

        let action: AIAction = engine.chooseAction(for: round, playerID: playerID)
        try action.apply(to: &round, playerID: playerID)

        // Handle multi-step turns
        while !round.isComplete {
            guard let nextID = round.currentPlayerID else { break }

            switch round.state {
            case .buyDecision(let id, _) where id == nextID:
                let buyAction: AIAction = engine.chooseAction(for: round, playerID: nextID)
                try buyAction.apply(to: &round, playerID: nextID)
            case .awaitingAction(let id) where id == nextID:
                let awaitAction: AIAction = engine.chooseAction(for: round, playerID: nextID)
                try awaitAction.apply(to: &round, playerID: nextID)
            default:
                break
            }

            // If we're back to preRoll for a different player or same player, break inner loop
            if case .preRoll = round.state { break }
            if case .gameComplete = round.state { break }
        }

        turnCount += 1
    }

    // The game may or may not complete within 2000 turns (Monopoly can be very long).
    // At minimum, it shouldn't crash.
    #expect(turnCount > 0)
}

// MARK: - Full Round Playthrough

@Test
func fullRoundPlaythrough() throws {
    var round: Round = try Round(
        board: .standardCooked(),
        players: makePlayers()
    )

    #expect(round.currentPlayerID == "alice")

    // Turn 1: Alice rolls and lands on firm 2 (FryChain, position 3, cost 60)
    try round.rollDice(cookedRoll: .init(die1: 1, die2: 2))
    #expect(round.playerStates[0].position == 3)
    if case .buyDecision(_, let firmID) = round.state {
        #expect(firmID == 2)
        try round.acquireFirm(playerID: "alice")
        #expect(round.board.firm(byID: 2)?.controllingCompany == "alice")
        #expect(round.playerStates[0].player.capital == 1440)
    } else {
        Issue.record("Expected buy decision for firm 2")
    }

    // Turn 2: Bob rolls
    #expect(round.currentPlayerID == "bob")
    try round.rollDice(cookedRoll: .init(die1: 3, die2: 3))
    // Position 6 = firm(3) = MegaMart (retail, cost 100)
    if case .buyDecision(_, let firmID) = round.state {
        #expect(firmID == 3)
        try round.acquireFirm(playerID: "bob")
        #expect(round.board.firm(byID: 3)?.controllingCompany == "bob")
    } else {
        // Doubles, so Bob gets another turn. Handle accordingly.
        // With doubles, position 6 is firm 3. Let's just verify it doesn't crash.
    }

    // Turn 3: Alice rolls (or Bob's extra turn from doubles)
    // Continue playing and verify no crashes
    var turnCount: Int = 2
    while !round.isComplete && turnCount < 50 {
        guard let playerID = round.currentPlayerID else { break }

        switch round.state {
        case .preRoll:
            try round.rollDice()
        case .buyDecision(_, _):
            try round.declineFirm(playerID: playerID)
        case .awaitingAction:
            try round.endTurn(playerID: playerID)
        default:
            break
        }
        turnCount += 1
    }

    #expect(turnCount >= 2)
    #expect(round.log.count > 0)
}

// MARK: - Card Effect Tests

@Test
func marketShockCardDraw() throws {
    var round: Round = try makeReadyRound()

    // Position 7 is marketShock
    round.playerStates[0].position = 4
    round.state = .preRoll(playerID: "alice")

    try round.rollDice(cookedRoll: .init(die1: 1, die2: 2))
    // Position 7 = marketShock
    #expect(round.playerStates[0].position == 7 || round.log.contains(where: {
        if case .drewMarketShock = $0.decision { return true }
        return false
    }))
}

@Test
func laborBoardCardDraw() throws {
    var round: Round = try makeReadyRound()

    // Position 2 is laborBoard
    round.playerStates[0].position = 0
    round.state = .preRoll(playerID: "alice")

    try round.rollDice(cookedRoll: .init(die1: 1, die2: 1))
    // Position 2 = laborBoard. Also doubles, so Alice gets another turn.
    let drewCard: Bool = round.log.contains(where: {
        if case .drewLaborBoard = $0.decision { return true }
        return false
    })
    #expect(drewCard)
}

// MARK: - Multi-Player Tests

@Test
func fourPlayerGame() throws {
    let players: [Player] = [
        Player(id: "p1", name: "Alice", capital: 1500, companyName: "Acme"),
        Player(id: "p2", name: "Bob", capital: 1500, companyName: "Apex"),
        Player(id: "p3", name: "Charlie", capital: 1500, companyName: "Nova"),
        Player(id: "p4", name: "Diana", capital: 1500, companyName: "Titan"),
    ]

    var round: Round = try Round(board: .standardCooked(), players: players)
    #expect(round.playerStates.count == 4)

    let engine: AIEngine = AIEngine(difficulty: .easy)
    var turnCount: Int = 0

    while !round.isComplete && turnCount < 500 {
        guard let playerID = round.currentPlayerID else { break }

        let action: AIAction = engine.chooseAction(for: round, playerID: playerID)
        try action.apply(to: &round, playerID: playerID)

        // Handle buy decisions within the same turn
        if case .buyDecision(let id, _) = round.state {
            let buyAction: AIAction = engine.chooseAction(for: round, playerID: id)
            try buyAction.apply(to: &round, playerID: id)
        }

        if case .awaitingAction(let id) = round.state {
            let awaitAction: AIAction = engine.chooseAction(for: round, playerID: id)
            try awaitAction.apply(to: &round, playerID: id)
        }

        turnCount += 1
    }

    #expect(turnCount > 0)
}

// MARK: - Edge Cases

@Test
func publicGrantCollects() throws {
    var round: Round = try makeReadyRound()
    round.publicGrantPool = 500

    // Position 20 is publicGrant
    round.playerStates[0].position = 17
    round.state = .preRoll(playerID: "alice")

    try round.rollDice(cookedRoll: .init(die1: 2, die2: 1))

    #expect(round.playerStates[0].player.capital == 1500 + 500)
    #expect(round.publicGrantPool == 0)
}

@Test
func campusBuild() throws {
    var round: Round = try makeReadyRound()

    round.board.firms[0].controllingCompany = "alice"
    round.board.firms[1].controllingCompany = "alice"
    round.board.firms[0].departments = 4
    round.board.firms[1].departments = 4

    round.state = .awaitingAction(playerID: "alice")

    try round.buildCampus(playerID: "alice", firmID: 1)

    let firm: Firm? = round.board.firm(byID: 1)
    #expect(firm?.hasCampus == true)
    #expect(firm?.departments == 0)
}
