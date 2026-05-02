import Foundation

public struct PlayerState: Equatable, Codable, Sendable {
    public var player: Player
    public var position: Int
    public var isInInvestigation: Bool
    public var turnsInInvestigation: Int
    public var settlementAgreements: Int
    public var isBankrupt: Bool
    public var doublesRolledInRow: Int

    public init(
        player: Player,
        position: Int = 0,
        isInInvestigation: Bool = false,
        turnsInInvestigation: Int = 0,
        settlementAgreements: Int = 0,
        isBankrupt: Bool = false,
        doublesRolledInRow: Int = 0
    ) {
        self.player = player
        self.position = position
        self.isInInvestigation = isInInvestigation
        self.turnsInInvestigation = turnsInInvestigation
        self.settlementAgreements = settlementAgreements
        self.isBankrupt = isBankrupt
        self.doublesRolledInRow = doublesRolledInRow
    }

    public var netWorth: Int {
        player.capital
    }
}
