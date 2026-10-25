import SwiftUI

struct ContentView: View {
    @State private var board = Board.standard()
    @State private var turn: PieceColor = .white
    @State private var selected: Square? = nil

    var body: some View {
        ZStack {
            Deco.ink.ignoresSafeArea()
            Sunburst()
                .fill(Deco.gold.opacity(0.07))
                .ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("CHESS")
                        .font(.system(size: 38, weight: .light, design: .serif))
                        .tracking(14)
                        .foregroundStyle(Deco.goldGradient)
                    DecoDivider().frame(maxWidth: 220)
                }

                TurnBanner(turn: turn, inCheck: board.inCheck(turn))

                BoardView(board: board,
                          selected: selected,
                          targets: Set(selected.map { board.legalMoves(from: $0) } ?? []),
                          onTap: tap)
                    .padding(.horizontal, 10)

                DecoDivider().frame(maxWidth: 220)
            }
        }
    }
}

extension ContentView {
    func tap(_ s: Square) {
        if let from = selected, board.legalMoves(from: from).contains(s) {
            board = board.applying(from, s)
            selected = nil
            turn = turn.opponent
            return
        }
        if let p = board[s], p.color == turn {
            selected = (selected == s) ? nil : s
        } else {
            selected = nil
        }
    }
}

struct TurnBanner: View {
    let turn: PieceColor
    let inCheck: Bool

    var body: some View {
        HStack(spacing: 10) {
            Diamond()
                .fill(turn == .white ? Deco.ivory : Deco.ink)
                .overlay(Diamond().stroke(Deco.gold, lineWidth: 1.2))
                .frame(width: 14, height: 14)
            Text(inCheck ? "\(turn.name.uppercased()) TO MOVE \u{2014} CHECK" : "\(turn.name.uppercased()) TO MOVE")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .tracking(4)
                .foregroundStyle(Deco.goldGradient)
        }
    }
}

struct BoardView: View {
    let board: Board
    var selected: Square? = nil
    var targets: Set<Square> = []
    var onTap: (Square) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 8
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { c in
                                let sq = Square(r: r, c: c)
                                SquareView(dark: (r + c) % 2 == 1, piece: board.squares[r][c],
                                           isSelected: selected == sq, isTarget: targets.contains(sq))
                                    .frame(width: cell, height: cell)
                                    .contentShape(Rectangle())
                                    .onTapGesture { onTap(sq) }
                            }
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .overlay(Rectangle().stroke(Deco.gold, lineWidth: 2))
            .padding(6)
            .overlay(Rectangle().stroke(Deco.gold.opacity(0.6), lineWidth: 1))
            .overlay(CornerOrnaments().stroke(Deco.gold, lineWidth: 1.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct SquareView: View {
    let dark: Bool
    let piece: Piece?
    var isSelected = false
    var isTarget = false

    var body: some View {
        ZStack {
            Rectangle().fill(dark ? Deco.deepGold.opacity(0.9) : Deco.ivory)
            // inset geometric motif: a thin diamond on every square
            Diamond()
                .stroke(dark ? Deco.gold.opacity(0.35) : Deco.cream, lineWidth: 0.8)
                .padding(5)
            if isSelected {
                Rectangle().fill(Deco.paleGold.opacity(0.55))
                Rectangle().stroke(Deco.gold, lineWidth: 2.5)
            }
            if let piece {
                PieceView(piece: piece).padding(2)
            }
            if isTarget {
                if piece == nil {
                    Diamond().fill(Deco.ink.opacity(0.55)).padding(14)
                    Diamond().stroke(Deco.gold, lineWidth: 1.2).padding(14)
                } else {
                    Diamond().stroke(Deco.ink.opacity(0.85), lineWidth: 3).padding(1)
                    Diamond().stroke(Deco.gold, lineWidth: 1.5).padding(1)
                }
            }
        }
    }
}

/// Stepped L-shaped ornaments on the four outer corners of the frame.
struct CornerOrnaments: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let s: CGFloat = 16
        for (x, y, dx, dy) in [(r.minX, r.minY, 1.0, 1.0), (r.maxX, r.minY, -1.0, 1.0),
                               (r.minX, r.maxY, 1.0, -1.0), (r.maxX, r.maxY, -1.0, -1.0)] {
            let ox = x - dx * 6, oy = y - dy * 6
            p.move(to: CGPoint(x: ox, y: oy + dy * s * 2))
            p.addLine(to: CGPoint(x: ox, y: oy))
            p.addLine(to: CGPoint(x: ox + dx * s * 2, y: oy))
            p.move(to: CGPoint(x: ox + dx * 4, y: oy + dy * s * 1.2))
            p.addLine(to: CGPoint(x: ox + dx * 4, y: oy + dy * 4))
            p.addLine(to: CGPoint(x: ox + dx * s * 1.2, y: oy + dy * 4))
        }
        return p
    }
}
