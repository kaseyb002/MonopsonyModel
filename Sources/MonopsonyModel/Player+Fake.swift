import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = "Player",
        imageURL: URL? = nil,
        capital: Int = 1500,
        companyName: String = "Acme Holdings"
    ) -> Player {
        Player(
            id: id,
            name: name,
            imageURL: imageURL,
            capital: capital,
            companyName: companyName
        )
    }
}
