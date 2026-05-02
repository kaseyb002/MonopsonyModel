import Foundation

extension Round {
    public init(
        id: String = UUID().uuidString,
        started: Date = .now,
        board: Board? = nil,
        players: [Player],
        cookedDice: [DiceRoll]? = nil
    ) throws {
        guard players.count >= 2 else { throw MonopsonyModelError.notEnoughPlayers }
        guard players.count <= 8 else { throw MonopsonyModelError.tooManyPlayers }

        self.id = id
        self.started = started
        self.board = board ?? .standard()

        self.playerStates = players.map { player in
            PlayerState(player: player)
        }

        self.currentPlayerIndex = 0
        self.lastDiceRoll = nil
        self.publicGrantPool = 0
        self.log = []
        self.ended = nil
        self.state = .preRoll(playerID: players[0].id)
    }
}
