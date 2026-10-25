import SwiftUI

struct ContentView: View {
    @State private var board = Board.standard()
    @State private var turn: PieceColor = .white
    @State private var selected: Square? = nil
    @State private var result: String? = nil
    @State private var lastMove: (from: Square, to: Square)? = nil
    @State private var history: [String] = []

    var body: some View {
        ZStack {
            Deco.ink.ignoresSafeArea()
            Sunburst()
                .fill(Deco.gold.opacity(0.07))
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("CHESS")
                        .font(.system(size: 38, weight: .light, design: .serif))
                        .tracking(14)
                        .foregroundStyle(Deco.goldGradient)
                    DecoDivider().frame(maxWidth: 220)
                }

                Group {
                    if let result {
                        Text(result)
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .tracking(4)
                            .foregroundStyle(Deco.goldGradient)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else {
                        TurnBanner(turn: turn, inCheck: board.inCheck(turn))
                    }
                }
                .frame(height: 28)

                BoardView(board: board,
                          selected: selected,
                          targets: Set(selected.map { board.legalMoves(from: $0) } ?? []),
                          lastFrom: lastMove?.from, lastTo: lastMove?.to,
                          checkedKing: board.inCheck(turn) ? board.kingSquare(turn) : nil,
                          onTap: tap)
                    .padding(.horizontal, 10)
                    .allowsHitTesting(result == nil)

                MoveHistory(moves: history)

                Button(action: reset) {
                    Text("RESET")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .tracking(6)
                        .foregroundColor(Deco.ink)
                        .padding(.horizontal, 34)
                        .padding(.vertical, 12)
                        .background(Deco.goldGradient)
                        .overlay(Rectangle().stroke(Deco.paleGold, lineWidth: 1).padding(3))
                }
                .buttonStyle(DecoPressStyle())
            }
            .padding(.vertical, 8)
        }
    }
}

extension ContentView {
    func reset() {
        withAnimation(.easeInOut(duration: 0.25)) {
            board = Board.standard()
            turn = .white
            selected = nil
            result = nil
            lastMove = nil
            history = []
        }
    }

    func tap(_ s: Square) {
        guard result == nil else { return }
        if let from = selected, board.legalMoves(from: from).contains(s) {
            let note = notation(from, s)
            withAnimation(.easeInOut(duration: 0.18)) {
                board = board.applying(from, s)
                lastMove = (from, s)
                selected = nil
                turn = turn.opponent
            }
            let mate = !board.hasAnyLegalMove(turn)
            let check = board.inCheck(turn)
            history.append(note + (mate && check ? "#" : check ? "+" : ""))
            if mate {
                withAnimation {
                    result = check
                        ? "CHECKMATE \u{2014} \(turn.opponent.name.uppercased()) WINS"
                        : "STALEMATE \u{2014} DRAW"
                }
            }
            return
        }
        if let p = board[s], p.color == turn {
            selected = (selected == s) ? nil : s
        } else {
            selected = nil
        }
    }

    /// Compact algebraic notation, e.g. e4, Nxf3, O-O, exd6, e8=Q.
    func notation(_ from: Square, _ to: Square) -> String {
        guard let p = board[from] else { return "" }
        let files = Array("abcdefgh")
        func name(_ s: Square) -> String { "\(files[s.c])\(8 - s.r)" }
        if p.kind == .king, abs(to.c - from.c) == 2 { return to.c > from.c ? "O-O" : "O-O-O" }
        let capture = board[to] != nil || (p.kind == .pawn && from.c != to.c)
        let letter: String
        switch p.kind {
        case .king: letter = "K"
        case .queen: letter = "Q"
        case .rook: letter = "R"
        case .bishop: letter = "B"
        case .knight: letter = "N"
        case .pawn: letter = capture ? String(files[from.c]) : ""
        }
        var s = letter + (capture ? "x" : "") + name(to)
        if p.kind == .pawn, to.r == 0 || to.r == 7 { s += "=Q" }
        return s
    }
}

struct DecoPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
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
            Diamond()
                .fill(turn == .white ? Deco.ivory : Deco.ink)
                .overlay(Diamond().stroke(Deco.gold, lineWidth: 1.2))
                .frame(width: 14, height: 14)
        }
    }
}

/// Numbered move pairs in a scrolling gold-framed strip; newest stays in view.
struct MoveHistory: View {
    let moves: [String]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    if moves.isEmpty {
                        Text("NO MOVES YET")
                            .foregroundColor(Deco.gold.opacity(0.5))
                    }
                    ForEach(0..<((moves.count + 1) / 2), id: \.self) { i in
                        HStack(spacing: 6) {
                            Text("\(i + 1).").foregroundColor(Deco.gold.opacity(0.6))
                            Text(moves[2 * i]).foregroundColor(Deco.ivory)
                            if 2 * i + 1 < moves.count {
                                Text(moves[2 * i + 1]).foregroundColor(Deco.paleGold)
                            }
                        }
                        .id(i)
                    }
                }
                .font(.system(size: 14, weight: .medium, design: .serif))
                .tracking(1)
                .padding(.horizontal, 14)
            }
            .frame(height: 36)
            .overlay(Rectangle().stroke(Deco.gold.opacity(0.7), lineWidth: 1))
            .padding(.horizontal, 16)
            .onChange(of: moves.count) { _ in
                withAnimation { proxy.scrollTo((moves.count - 1) / 2, anchor: .trailing) }
            }
        }
    }
}

struct BoardView: View {
    let board: Board
    var selected: Square? = nil
    var targets: Set<Square> = []
    var lastFrom: Square? = nil
    var lastTo: Square? = nil
    var checkedKing: Square? = nil
    var onTap: (Square) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 8
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { c in
                            let sq = Square(r: r, c: c)
                            SquareView(dark: (r + c) % 2 == 1, piece: board.squares[r][c],
                                       isSelected: selected == sq, isTarget: targets.contains(sq),
                                       isLastMove: sq == lastFrom || sq == lastTo,
                                       isChecked: sq == checkedKing,
                                       rankLabel: c == 0 ? "\(8 - r)" : nil,
                                       fileLabel: r == 7 ? String(Array("abcdefgh")[c]) : nil)
                                .frame(width: cell, height: cell)
                                .contentShape(Rectangle())
                                .onTapGesture { onTap(sq) }
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
    var isLastMove = false
    var isChecked = false
    var rankLabel: String? = nil
    var fileLabel: String? = nil

    var body: some View {
        ZStack {
            Rectangle().fill(dark ? Deco.deepGold.opacity(0.9) : Deco.ivory)
            // inset geometric motif: a thin diamond on every square
            Diamond()
                .stroke(dark ? Deco.gold.opacity(0.35) : Deco.cream, lineWidth: 0.8)
                .padding(5)
            if isLastMove {
                Rectangle().fill(Deco.gold.opacity(dark ? 0.35 : 0.45))
            }
            if isChecked {
                RadialGradient(colors: [Color(red: 0.75, green: 0.12, blue: 0.10).opacity(0.85), .clear],
                               center: .center, startRadius: 2, endRadius: 30)
            }
            if isSelected {
                Rectangle().fill(Deco.paleGold.opacity(0.55))
                Rectangle().strokeBorder(Deco.ink, lineWidth: 1).padding(2)
                Rectangle().strokeBorder(Deco.gold, lineWidth: 2.5)
            }
            labels
            if let piece {
                PieceView(piece: piece)
                    .padding(2)
                    .scaleEffect(isSelected ? 1.08 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
            }
            if isTarget {
                if piece == nil {
                    Diamond().fill(Deco.ink.opacity(0.6)).padding(15)
                    Diamond().stroke(Deco.paleGold, lineWidth: 1.2).padding(15)
                } else {
                    TargetCorners().stroke(Deco.ink, lineWidth: 4)
                    TargetCorners().stroke(Deco.paleGold, lineWidth: 2)
                }
            }
        }
    }

    private var labels: some View {
        let color = dark ? Deco.ivory.opacity(0.8) : Deco.deepGold
        return ZStack {
            if let rankLabel {
                Text(rankLabel).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(2)
            }
            if let fileLabel {
                Text(fileLabel).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(2)
            }
        }
        .font(.system(size: 9, weight: .bold, design: .serif))
        .foregroundColor(color)
    }
}

/// Four angular corner brackets marking a capturable piece.
struct TargetCorners: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let s = r.width * 0.28, i: CGFloat = 2
        for (x, y, dx, dy) in [(r.minX + i, r.minY + i, 1.0, 1.0), (r.maxX - i, r.minY + i, -1.0, 1.0),
                               (r.minX + i, r.maxY - i, 1.0, -1.0), (r.maxX - i, r.maxY - i, -1.0, -1.0)] {
            p.move(to: CGPoint(x: x, y: y + dy * s))
            p.addLine(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x + dx * s, y: y))
        }
        return p
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
