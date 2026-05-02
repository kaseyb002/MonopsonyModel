import Foundation

public struct Board: Equatable, Codable, Sendable {
    public let spaces: [BoardSpace]
    public var firms: [Firm]
    public var marketShockDeck: [MarketShockCard]
    public var laborBoardDeck: [LaborBoardCard]
    public var marketShockDiscard: [MarketShockCard]
    public var laborBoardDiscard: [LaborBoardCard]

    public init(
        spaces: [BoardSpace],
        firms: [Firm],
        marketShockDeck: [MarketShockCard],
        laborBoardDeck: [LaborBoardCard]
    ) {
        self.spaces = spaces
        self.firms = firms
        self.marketShockDeck = marketShockDeck
        self.laborBoardDeck = laborBoardDeck
        self.marketShockDiscard = []
        self.laborBoardDiscard = []
    }

    public var spaceCount: Int { spaces.count }

    public func firm(byID id: FirmID) -> Firm? {
        firms.first(where: { $0.id == id })
    }

    public mutating func updateFirm(_ firm: Firm) {
        guard let idx = firms.firstIndex(where: { $0.id == firm.id }) else { return }
        firms[idx] = firm
    }

    public func firmsInIndustry(_ industry: Industry) -> [Firm] {
        firms.filter { $0.industry == industry }
    }

    public func playerControlsIndustry(_ playerID: PlayerID, industry: Industry) -> Bool {
        let industryFirms: [Firm] = firmsInIndustry(industry)
        guard !industryFirms.isEmpty else { return false }
        return industryFirms.allSatisfy { $0.controllingCompany == playerID && !$0.isFrozen }
    }

    public mutating func drawMarketShock() -> MarketShockCard? {
        if marketShockDeck.isEmpty {
            marketShockDeck = marketShockDiscard.shuffled()
            marketShockDiscard.removeAll()
        }
        guard !marketShockDeck.isEmpty else { return nil }
        return marketShockDeck.removeFirst()
    }

    public mutating func drawLaborBoard() -> LaborBoardCard? {
        if laborBoardDeck.isEmpty {
            laborBoardDeck = laborBoardDiscard.shuffled()
            laborBoardDiscard.removeAll()
        }
        guard !laborBoardDeck.isEmpty else { return nil }
        return laborBoardDeck.removeFirst()
    }

    public mutating func discardMarketShock(_ card: MarketShockCard) {
        marketShockDiscard.append(card)
    }

    public mutating func discardLaborBoard(_ card: LaborBoardCard) {
        laborBoardDiscard.append(card)
    }
}
