import Foundation

extension Round {
    public func netWorth(for playerID: PlayerID) -> Int {
        guard let ps = playerState(for: playerID) else { return 0 }
        return totalAssetValue(for: ps)
    }

    public func firmValue(_ firm: Firm) -> Int {
        if firm.isFrozen {
            return firm.frozenValue
        }
        return firm.totalInvestment
    }

    public func rankings() -> [(player: Player, netWorth: Int)] {
        playerStates
            .map { (player: $0.player, netWorth: totalAssetValue(for: $0)) }
            .sorted { $0.netWorth > $1.netWorth }
    }

    public func winner() -> Player? {
        if case .gameComplete(let winner) = state {
            return winner
        }
        return nil
    }
}
