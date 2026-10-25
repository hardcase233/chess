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

struct Square: Hashable { let r: Int; let c: Int }

extension PieceColor {
    var opponent: PieceColor { self == .white ? .black : .white }
    var name: String { self == .white ? "White" : "Black" }
}

extension Board {
    subscript(_ s: Square) -> Piece? {
        get { squares[s.r][s.c] }
        set { squares[s.r][s.c] = newValue }
    }

    static func inside(_ r: Int, _ c: Int) -> Bool { (0..<8).contains(r) && (0..<8).contains(c) }

    /// Moves following each piece's movement pattern, ignoring whether the own king is left in check.
    func pseudoMoves(from s: Square) -> [Square] {
        guard let p = self[s] else { return [] }
        var out: [Square] = []

        func slide(_ dirs: [(Int, Int)]) {
            for (dr, dc) in dirs {
                var r = s.r + dr, c = s.c + dc
                while Board.inside(r, c) {
                    if let q = squares[r][c] {
                        if q.color != p.color { out.append(Square(r: r, c: c)) }
                        break
                    }
                    out.append(Square(r: r, c: c))
                    r += dr; c += dc
                }
            }
        }
        func step(_ offs: [(Int, Int)]) {
            for (dr, dc) in offs {
                let r = s.r + dr, c = s.c + dc
                guard Board.inside(r, c) else { continue }
                if let q = squares[r][c], q.color == p.color { continue }
                out.append(Square(r: r, c: c))
            }
        }

        let straight = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        let diagonal = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        switch p.kind {
        case .rook: slide(straight)
        case .bishop: slide(diagonal)
        case .queen: slide(straight + diagonal)
        case .king: step(straight + diagonal)
        case .knight: step([(2, 1), (2, -1), (-2, 1), (-2, -1), (1, 2), (1, -2), (-1, 2), (-1, -2)])
        case .pawn:
            let dir = p.color == .white ? -1 : 1
            let startRow = p.color == .white ? 6 : 1
            let r1 = s.r + dir
            if Board.inside(r1, s.c), squares[r1][s.c] == nil {
                out.append(Square(r: r1, c: s.c))
                let r2 = s.r + 2 * dir
                if s.r == startRow, squares[r2][s.c] == nil { out.append(Square(r: r2, c: s.c)) }
            }
            for dc in [-1, 1] {
                let c = s.c + dc
                if Board.inside(r1, c), let q = squares[r1][c], q.color != p.color {
                    out.append(Square(r: r1, c: c))
                }
            }
        }
        return out
    }

    func kingSquare(_ color: PieceColor) -> Square? {
        for r in 0..<8 { for c in 0..<8 where squares[r][c] == Piece(kind: .king, color: color) {
            return Square(r: r, c: c)
        } }
        return nil
    }

    func isAttacked(_ target: Square, by color: PieceColor) -> Bool {
        for r in 0..<8 { for c in 0..<8 where squares[r][c]?.color == color {
            if pseudoMoves(from: Square(r: r, c: c)).contains(target) { return true }
        } }
        return false
    }

    func inCheck(_ color: PieceColor) -> Bool {
        guard let k = kingSquare(color) else { return false }
        return isAttacked(k, by: color.opponent)
    }

    func applying(_ from: Square, _ to: Square) -> Board {
        var b = self
        b[to] = b[from]
        b[from] = nil
        return b
    }

    /// Pseudo moves that do not leave the mover's own king in check.
    func legalMoves(from s: Square) -> [Square] {
        guard let p = self[s] else { return [] }
        return pseudoMoves(from: s).filter { !applying(s, $0).inCheck(p.color) }
    }
}
