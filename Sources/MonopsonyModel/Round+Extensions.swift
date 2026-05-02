import Foundation

extension Round {
    public var isComplete: Bool {
        if case .gameComplete = state { return true }
        return false
    }

    public var currentPlayerID: PlayerID? {
        switch state {
        case .preRoll(let id): id
        case .postRoll(let id, _): id
        case .buyDecision(let id, _): id
        case .awaitingAction(let id): id
        case .gameComplete: nil
        }
    }

    public var currentPlayer: Player? {
        guard let id = currentPlayerID else { return nil }
        return player(byID: id)
    }

    public func player(byID id: PlayerID) -> Player? {
        playerStates.first(where: { $0.player.id == id })?.player
    }

    public func playerState(for playerID: PlayerID) -> PlayerState? {
        playerStates.first(where: { $0.player.id == playerID })
    }

    public func playerStateIndex(for playerID: PlayerID) -> Int? {
        playerStates.firstIndex(where: { $0.player.id == playerID })
    }

    public func firmsOwned(by playerID: PlayerID) -> [Firm] {
        board.firms.filter { $0.controllingCompany == playerID }
    }

    public func totalAssetValue(for playerState: PlayerState) -> Int {
        var total: Int = playerState.player.capital
        let owned: [Firm] = firmsOwned(by: playerState.player.id)
        for firm in owned {
            total += firm.totalInvestment
        }
        return total
    }

    public var activePlayers: [PlayerState] {
        playerStates.filter { !$0.isBankrupt }
    }

    public var activePlayerCount: Int {
        activePlayers.count
    }
}

extension Round.State {
    public var isComplete: Bool {
        switch self {
        case .gameComplete: true
        case .preRoll, .postRoll, .buyDecision, .awaitingAction: false
        }
    }
}
