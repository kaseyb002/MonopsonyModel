import Foundation

extension PlayerState {
    public static func fake(
        player: Player = .fake(),
        position: Int = 0,
        isInInvestigation: Bool = false,
        turnsInInvestigation: Int = 0,
        settlementAgreements: Int = 0,
        isBankrupt: Bool = false,
        doublesRolledInRow: Int = 0
    ) -> PlayerState {
        PlayerState(
            player: player,
            position: position,
            isInInvestigation: isInInvestigation,
            turnsInInvestigation: turnsInInvestigation,
            settlementAgreements: settlementAgreements,
            isBankrupt: isBankrupt,
            doublesRolledInRow: doublesRolledInRow
        )
    }
}
