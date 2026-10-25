import Foundation

enum PieceColor { case white, black }
enum PieceKind { case king, queen, rook, bishop, knight, pawn }

struct Piece: Equatable {
    let kind: PieceKind
    let color: PieceColor
}

struct Board {
    /// squares[row][col], row 0 is black's back rank (top of screen).
    var squares: [[Piece?]]

    static func standard() -> Board {
        let back: [PieceKind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        var s: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        for c in 0..<8 {
            s[0][c] = Piece(kind: back[c], color: .black)
            s[1][c] = Piece(kind: .pawn, color: .black)
            s[6][c] = Piece(kind: .pawn, color: .white)
            s[7][c] = Piece(kind: back[c], color: .white)
        }
        return Board(squares: s)
    }
}
