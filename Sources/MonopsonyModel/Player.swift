import Foundation

public typealias PlayerID = String

public struct Player: Equatable, Codable, Sendable, Identifiable {
    public let id: PlayerID
    public var name: String
    public var imageURL: URL?
    public var capital: Int
    public var companyName: String

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case capital
        case companyName
    }

    public init(
        id: PlayerID,
        name: String,
        imageURL: URL? = nil,
        capital: Int = 1500,
        companyName: String = "Holdings Inc."
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.capital = capital
        self.companyName = companyName
    }
}
