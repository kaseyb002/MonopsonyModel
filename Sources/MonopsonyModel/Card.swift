import Foundation

public typealias CardID = Int

public struct MarketShockCard: Equatable, Codable, Sendable, Identifiable {
    public let id: CardID
    public let title: String
    public let description: String
    public let effect: CardEffect

    public init(id: CardID, title: String, description: String, effect: CardEffect) {
        self.id = id
        self.title = title
        self.description = description
        self.effect = effect
    }
}

public struct LaborBoardCard: Equatable, Codable, Sendable, Identifiable {
    public let id: CardID
    public let title: String
    public let description: String
    public let effect: CardEffect

    public init(id: CardID, title: String, description: String, effect: CardEffect) {
        self.id = id
        self.title = title
        self.description = description
        self.effect = effect
    }
}

public enum CardEffect: Equatable, Codable, Sendable {
    case gainCapital(Int)
    case loseCapital(Int)
    case moveToSpace(Int)
    case moveSpaces(Int)
    case antitrustProbe
    case settlementAgreement
    case payEachPlayer(Int)
    case collectFromEachPlayer(Int)
    case repairCost(perDepartment: Int, perCampus: Int)
}
