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
    /// Original squares of kings and rooks that have not moved yet (castling rights).
    var unmoved: Set<Square> = [Square(r: 7, c: 4), Square(r: 7, c: 0), Square(r: 7, c: 7),
                                Square(r: 0, c: 4), Square(r: 0, c: 0), Square(r: 0, c: 7)]
    /// Square a pawn skipped on the previous move, capturable en passant this turn.
    var enPassant: Square? = nil

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
                guard Board.inside(r1, c) else { continue }
                if let q = squares[r1][c], q.color != p.color {
                    out.append(Square(r: r1, c: c))
                } else if enPassant == Square(r: r1, c: c) {
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
        guard let p = b[from] else { return b }
        b.enPassant = nil

        // En passant: pawn moves diagonally onto the empty skipped square.
        if p.kind == .pawn, from.c != to.c, b[to] == nil {
            b[Square(r: from.r, c: to.c)] = nil
        }
        // Castling: king moves two files; bring the rook across.
        if p.kind == .king, abs(to.c - from.c) == 2 {
            let rookFrom = Square(r: from.r, c: to.c > from.c ? 7 : 0)
            let rookTo = Square(r: from.r, c: to.c > from.c ? 5 : 3)
            b[rookTo] = b[rookFrom]
            b[rookFrom] = nil
        }
        // Double pawn push opens an en passant chance for one turn.
        if p.kind == .pawn, abs(to.r - from.r) == 2 {
            b.enPassant = Square(r: (from.r + to.r) / 2, c: from.c)
        }

        b[to] = p
        b[from] = nil

        // Promotion: always to a queen.
        if p.kind == .pawn, to.r == 0 || to.r == 7 {
            b[to] = Piece(kind: .queen, color: p.color)
        }
        // Moving from, or being captured on, an original king/rook square ends that right.
        b.unmoved.remove(from)
        b.unmoved.remove(to)
        return b
    }

    /// Castling destinations for the king on `s`, checking every rule.
    func castlingMoves(from s: Square) -> [Square] {
        guard let p = self[s], p.kind == .king, unmoved.contains(s) else { return [] }
        let enemy = p.color.opponent
        guard !isAttacked(s, by: enemy) else { return [] }
        var out: [Square] = []
        // kingside: rook on h-file, f and g empty and not attacked
        if unmoved.contains(Square(r: s.r, c: 7)), self[Square(r: s.r, c: 7)] == Piece(kind: .rook, color: p.color),
           squares[s.r][5] == nil, squares[s.r][6] == nil,
           !isAttacked(Square(r: s.r, c: 5), by: enemy), !isAttacked(Square(r: s.r, c: 6), by: enemy) {
            out.append(Square(r: s.r, c: 6))
        }
        // queenside: rook on a-file, b, c, d empty; d and c not attacked
        if unmoved.contains(Square(r: s.r, c: 0)), self[Square(r: s.r, c: 0)] == Piece(kind: .rook, color: p.color),
           squares[s.r][1] == nil, squares[s.r][2] == nil, squares[s.r][3] == nil,
           !isAttacked(Square(r: s.r, c: 3), by: enemy), !isAttacked(Square(r: s.r, c: 2), by: enemy) {
            out.append(Square(r: s.r, c: 2))
        }
        return out
    }

    /// Moves that do not leave the mover's own king in check, including castling.
    func legalMoves(from s: Square) -> [Square] {
        guard let p = self[s] else { return [] }
        let candidates = pseudoMoves(from: s) + castlingMoves(from: s)
        return candidates.filter { !applying(s, $0).inCheck(p.color) }
    }
}
