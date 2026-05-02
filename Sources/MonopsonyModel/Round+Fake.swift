import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .now,
        board: Board? = nil,
        players: [Player] = [
            .fake(id: "p1", name: "Alice", companyName: "Acme Holdings"),
            .fake(id: "p2", name: "Bob", companyName: "Apex Industries"),
        ]
    ) throws -> Round {
        try Round(
            id: id,
            started: started,
            board: board,
            players: players
        )
    }

    public static func fakeCompleted(
        id: String = "completed-game",
        started: Date = Date(timeIntervalSinceNow: -3600)
    ) throws -> Round {
        let p1: Player = .fake(id: "p1", name: "Alice", capital: 1500, companyName: "Acme Holdings")
        let p2: Player = .fake(id: "p2", name: "Bob", capital: 1500, companyName: "Apex Industries")

        var round: Round = try Round(
            id: id,
            started: started,
            board: .standardCooked(),
            players: [p1, p2]
        )

        // Give Alice some firms directly
        for i in board(round).firms.indices where [1, 2, 3, 4, 5].contains(round.board.firms[i].id) {
            round.board.firms[i].controllingCompany = p1.id
        }

        // Give Bob some firms
        for i in round.board.firms.indices where [6, 7, 8, 23, 24].contains(round.board.firms[i].id) {
            round.board.firms[i].controllingCompany = p2.id
        }

        // Set final positions and capital
        round.playerStates[0].player.capital = 2500
        round.playerStates[0].position = 15
        round.playerStates[1].player.capital = 800
        round.playerStates[1].position = 30
        round.playerStates[1].isBankrupt = true

        // Log a few representative actions
        round.log = [
            .init(playerID: p1.id, decision: .rolled(.init(die1: 4, die2: 3)),
                  timestamp: started.addingTimeInterval(60)),
            .init(playerID: p1.id, decision: .acquiredFirm(firmID: 1, cost: 60),
                  timestamp: started.addingTimeInterval(65)),
            .init(playerID: p2.id, decision: .rolled(.init(die1: 5, die2: 6)),
                  timestamp: started.addingTimeInterval(120)),
            .init(playerID: p2.id, decision: .acquiredFirm(firmID: 6, cost: 140),
                  timestamp: started.addingTimeInterval(125)),
            .init(playerID: p1.id, decision: .paidWagePremium(firmID: 6, toPlayer: p2.id, amount: 10),
                  timestamp: started.addingTimeInterval(200)),
            .init(playerID: p2.id, decision: .wentBankrupt,
                  timestamp: started.addingTimeInterval(3500)),
        ]

        round.ended = started.addingTimeInterval(3600)
        round.state = .gameComplete(winner: p1)

        return round
    }

    private static func board(_ round: Round) -> Board {
        round.board
    }
}
