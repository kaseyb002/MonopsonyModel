import Foundation

public struct Round: Equatable, Codable, Sendable {
    // MARK: - Constants

    public static let maxLogActions: Int = 100
    public static let payrollSalary: Int = 200
    public static let payrollTaxAmount: Int = 200
    public static let complianceFineAmount: Int = 100
    public static let investigationBailCost: Int = 50
    public static let maxTurnsInInvestigation: Int = 3
    public static let startingCapital: Int = 1500
    public static let maxDoublesBeforeProbe: Int = 3

    // MARK: - Initialized Properties

    public let id: String
    public let started: Date

    // MARK: - Game State

    public internal(set) var state: State
    public internal(set) var board: Board
    public internal(set) var playerStates: [PlayerState]
    public internal(set) var currentPlayerIndex: Int
    public internal(set) var lastDiceRoll: DiceRoll?
    public internal(set) var publicGrantPool: Int

    // MARK: - Results

    public internal(set) var log: [Action]
    public internal(set) var ended: Date?

    // MARK: - State

    public enum State: Equatable, Codable, Sendable {
        case preRoll(playerID: PlayerID)
        case postRoll(playerID: PlayerID, diceRoll: DiceRoll)
        case buyDecision(playerID: PlayerID, firmID: FirmID)
        case awaitingAction(playerID: PlayerID)
        case gameComplete(winner: Player)

        public var logValue: String {
            switch self {
            case .preRoll(let id):
                "Waiting for \(id) to roll"
            case .postRoll(let id, let roll):
                "\(id) rolled \(roll.total)"
            case .buyDecision(let id, let firmID):
                "\(id) deciding whether to acquire firm \(firmID)"
            case .awaitingAction(let id):
                "Waiting for \(id) to act"
            case .gameComplete(let winner):
                "\(winner.companyName) won the game!"
            }
        }
    }

    // MARK: - Dice Roll

    public struct DiceRoll: Equatable, Codable, Sendable {
        public let die1: Int
        public let die2: Int

        public var total: Int { die1 + die2 }
        public var isDoubles: Bool { die1 == die2 }

        public init(die1: Int, die2: Int) {
            self.die1 = die1
            self.die2 = die2
        }

        public static func random() -> DiceRoll {
            DiceRoll(die1: Int.random(in: 1...6), die2: Int.random(in: 1...6))
        }
    }

    // MARK: - Action Log

    public struct Action: Equatable, Codable, Sendable {
        public let playerID: PlayerID
        public let decision: Decision
        public let timestamp: Date

        public enum Decision: Equatable, Codable, Sendable {
            case rolled(DiceRoll)
            case acquiredFirm(firmID: FirmID, cost: Int)
            case declinedFirm(firmID: FirmID)
            case paidWagePremium(firmID: FirmID, toPlayer: PlayerID, amount: Int)
            case builtDepartment(firmID: FirmID, cost: Int)
            case builtCampus(firmID: FirmID, cost: Int)
            case frozeHiring(firmID: FirmID, received: Int)
            case resumedHiring(firmID: FirmID, cost: Int)
            case drewMarketShock(title: String)
            case drewLaborBoard(title: String)
            case collectedPayroll(amount: Int)
            case paidPayrollTax(amount: Int)
            case paidComplianceFine(amount: Int)
            case sentToInvestigation
            case escapedInvestigation(method: EscapeMethod)
            case wentBankrupt
            case passedTurn

            public enum EscapeMethod: String, Equatable, Codable, Sendable {
                case rolledDoubles
                case paidBail
                case usedSettlement
            }
        }

        public enum CodingKeys: String, CodingKey {
            case playerID = "playerId"
            case decision
            case timestamp
        }

        public init(
            playerID: PlayerID,
            decision: Decision,
            timestamp: Date = .now
        ) {
            self.playerID = playerID
            self.decision = decision
            self.timestamp = timestamp
        }
    }
}
