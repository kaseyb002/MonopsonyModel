import Foundation

public enum PlayerColor: String, Equatable, Codable, CaseIterable, Sendable {
    case blue
    case red
    case green
    case yellow
    case purple
    case orange
    case black
    case white

    public var displayableName: String {
        switch self {
        case .blue: "Blue"
        case .red: "Red"
        case .green: "Green"
        case .yellow: "Yellow"
        case .purple: "Purple"
        case .orange: "Orange"
        case .black: "Black"
        case .white: "White"
        }
    }
}
