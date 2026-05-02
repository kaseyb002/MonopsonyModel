import Foundation

// MARK: - Difficulty

public enum AIDifficulty: String, Equatable, Codable, Sendable, CaseIterable {
    case easy
    case medium
    case hard
}

// MARK: - AI Action

public enum AIAction: Equatable, Sendable {
    case roll
    case acquireFirm
    case declineFirm
    case buildDepartment(firmID: FirmID)
    case buildCampus(firmID: FirmID)
    case freezeHiring(firmID: FirmID)
    case resumeHiring(firmID: FirmID)
    case payBail
    case useSettlement
    case endTurn

    public func apply(to round: inout Round, playerID: PlayerID) throws {
        switch self {
        case .roll:
            try round.rollDice()
        case .acquireFirm:
            try round.acquireFirm(playerID: playerID)
        case .declineFirm:
            try round.declineFirm(playerID: playerID)
        case .buildDepartment(let firmID):
            try round.buildDepartment(playerID: playerID, firmID: firmID)
        case .buildCampus(let firmID):
            try round.buildCampus(playerID: playerID, firmID: firmID)
        case .freezeHiring(let firmID):
            try round.freezeHiring(playerID: playerID, firmID: firmID)
        case .resumeHiring(let firmID):
            try round.resumeHiring(playerID: playerID, firmID: firmID)
        case .payBail:
            try round.payBail(playerID: playerID)
        case .useSettlement:
            try round.useSettlementAgreement(playerID: playerID)
        case .endTurn:
            try round.endTurn(playerID: playerID)
        }
    }
}

// MARK: - AIEngine

public struct AIEngine: Sendable {
    public let difficulty: AIDifficulty

    public init(difficulty: AIDifficulty = .medium) {
        self.difficulty = difficulty
    }

    // MARK: Public API

    public func chooseAction(for round: Round, playerID: PlayerID) -> AIAction {
        switch round.state {
        case .preRoll(let id) where id == playerID:
            return handlePreRoll(round: round, playerID: playerID)
        case .buyDecision(let id, let firmID) where id == playerID:
            return handleBuyDecision(round: round, playerID: playerID, firmID: firmID)
        case .awaitingAction(let id) where id == playerID:
            return handleAwaitingAction(round: round, playerID: playerID)
        default:
            return .endTurn
        }
    }

    public func makeMove(on round: inout Round, playerID: PlayerID) throws {
        let action: AIAction = chooseAction(for: round, playerID: playerID)
        try action.apply(to: &round, playerID: playerID)
    }

    // MARK: - Pre-Roll

    private func handlePreRoll(round: Round, playerID: PlayerID) -> AIAction {
        guard let ps = round.playerState(for: playerID) else { return .roll }

        if ps.isInInvestigation {
            if ps.settlementAgreements > 0 {
                return .useSettlement
            }
            if difficulty == .hard && ps.turnsInInvestigation < Round.maxTurnsInInvestigation - 1 {
                return .roll
            }
            if ps.player.capital >= Round.investigationBailCost && ps.turnsInInvestigation >= 1 {
                return .payBail
            }
            return .roll
        }

        return .roll
    }

    // MARK: - Buy Decision

    private func handleBuyDecision(round: Round, playerID: PlayerID, firmID: FirmID) -> AIAction {
        guard let ps = round.playerState(for: playerID) else { return .declineFirm }
        guard let firm = round.board.firm(byID: firmID) else { return .declineFirm }

        let capitalAfter: Int = ps.player.capital - firm.acquisitionCost

        switch difficulty {
        case .easy:
            if capitalAfter >= 100 { return .acquireFirm }
            return .declineFirm

        case .medium:
            if capitalAfter >= 50 { return .acquireFirm }
            if wouldCompleteIndustry(firm: firm, playerID: playerID, round: round) && capitalAfter >= 0 {
                return .acquireFirm
            }
            return .declineFirm

        case .hard:
            if wouldCompleteIndustry(firm: firm, playerID: playerID, round: round) && capitalAfter >= 0 {
                return .acquireFirm
            }
            if capitalAfter >= 100 { return .acquireFirm }
            let firmsInIndustry: [Firm] = round.board.firmsInIndustry(firm.industry)
            let ownedInIndustry: Int = firmsInIndustry.filter { $0.controllingCompany == playerID }.count
            if ownedInIndustry > 0 && capitalAfter >= 0 {
                return .acquireFirm
            }
            if capitalAfter >= 200 { return .acquireFirm }
            return .declineFirm
        }
    }

    // MARK: - Awaiting Action (Build / Freeze / Resume / End)

    private func handleAwaitingAction(round: Round, playerID: PlayerID) -> AIAction {
        guard let ps = round.playerState(for: playerID) else { return .endTurn }

        // Try building if we can
        if let buildAction = tryBuild(round: round, playerID: playerID, capital: ps.player.capital) {
            return buildAction
        }

        // Try unfreezing profitable firms
        if difficulty != .easy {
            if let resumeAction = tryResume(round: round, playerID: playerID, capital: ps.player.capital) {
                return resumeAction
            }
        }

        // Freeze hiring on low-value firms if cash is critical
        if ps.player.capital < 100 {
            if let freezeAction = tryFreeze(round: round, playerID: playerID) {
                return freezeAction
            }
        }

        return .endTurn
    }

    // MARK: - Helpers

    private func wouldCompleteIndustry(firm: Firm, playerID: PlayerID, round: Round) -> Bool {
        let firmsInIndustry: [Firm] = round.board.firmsInIndustry(firm.industry)
        let ownedCount: Int = firmsInIndustry.filter { $0.controllingCompany == playerID }.count
        return ownedCount == firmsInIndustry.count - 1
    }

    private func tryBuild(round: Round, playerID: PlayerID, capital: Int) -> AIAction? {
        let industriesControlled: [Industry] = Industry.allCases.filter {
            round.board.playerControlsIndustry(playerID, industry: $0)
        }

        guard !industriesControlled.isEmpty else { return nil }

        let reserveCapital: Int
        switch difficulty {
        case .easy: reserveCapital = 200
        case .medium: reserveCapital = 150
        case .hard: reserveCapital = 100
        }

        for industry in industriesControlled {
            let industryFirms: [Firm] = round.board.firmsInIndustry(industry).filter {
                $0.controllingCompany == playerID && !$0.isFrozen
            }

            // Try campus first (requires all at max departments)
            let allMaxed: Bool = industryFirms.allSatisfy { $0.departments == Firm.maxDepartments }
            if allMaxed {
                if let campusTarget = industryFirms.first(where: { !$0.hasCampus }) {
                    if capital - campusTarget.campusCost >= reserveCapital {
                        return .buildCampus(firmID: campusTarget.id)
                    }
                }
            }

            // Try department (even building)
            let minDepts: Int = industryFirms.map(\.departments).min() ?? 0
            if let buildTarget = industryFirms.first(where: {
                $0.departments == minDepts && $0.departments < Firm.maxDepartments && !$0.hasCampus
            }) {
                if capital - buildTarget.departmentCost >= reserveCapital {
                    return .buildDepartment(firmID: buildTarget.id)
                }
            }
        }

        return nil
    }

    private func tryResume(round: Round, playerID: PlayerID, capital: Int) -> AIAction? {
        let frozenFirms: [Firm] = round.firmsOwned(by: playerID).filter(\.isFrozen)
        for firm in frozenFirms {
            let cost: Int = firm.frozenValue + firm.unfreezeExtra
            if capital - cost >= 200 {
                return .resumeHiring(firmID: firm.id)
            }
        }
        return nil
    }

    private func tryFreeze(round: Round, playerID: PlayerID) -> AIAction? {
        let ownedFirms: [Firm] = round.firmsOwned(by: playerID).filter {
            !$0.isFrozen && $0.departments == 0 && !$0.hasCampus
        }
        if let cheapest = ownedFirms.min(by: { $0.acquisitionCost < $1.acquisitionCost }) {
            return .freezeHiring(firmID: cheapest.id)
        }
        return nil
    }
}

// MARK: - Round Extension for AI

extension Round {
    public mutating func makeAIMove(difficulty: AIDifficulty = .medium) throws {
        guard let playerID = currentPlayerID else {
            throw MonopsonyModelError.notWaitingForPlayerToAct
        }
        try AIEngine(difficulty: difficulty).makeMove(on: &self, playerID: playerID)
    }
}
