import SwiftUI

// MARK: - Models

enum Direction {
    case up, down, left, right
}

struct Position: Equatable, Hashable {
    var x: Int
    var y: Int
}

// MARK: - Game Logic

@Observable
class SnakeGame {
    let gridSize = 20
    var snake: [Position] = []
    var food: Position = Position(x: 0, y: 0)
    var direction: Direction = .right
    var nextDirection: Direction = .right
    var isGameOver = false
    var score = 0
    var bestScore = 0
    var timer: Timer?

    init() {
        reset()
    }

    func reset() {
        let mid = gridSize / 2
        snake = [
            Position(x: mid, y: mid),
            Position(x: mid - 1, y: mid),
            Position(x: mid - 2, y: mid)
        ]
        direction = .right
        nextDirection = .right
        isGameOver = false
        score = 0
        spawnFood()
    }

    func spawnFood() {
        var pos: Position
        repeat {
            pos = Position(
                x: Int.random(in: 0..<gridSize),
                y: Int.random(in: 0..<gridSize)
            )
        } while snake.contains(pos)
        food = pos
    }

    func changeDirection(_ newDir: Direction) {
        let opposites: [Direction: Direction] = [.up: .down, .down: .up, .left: .right, .right: .left]
        if opposites[newDir] != direction {
            nextDirection = newDir
        }
    }

    func tick() {
        guard !isGameOver else { return }

        direction = nextDirection
        guard let head = snake.first else { return }

        var newHead: Position
        switch direction {
        case .up:    newHead = Position(x: head.x, y: head.y - 1)
        case .down:  newHead = Position(x: head.x, y: head.y + 1)
        case .left:  newHead = Position(x: head.x - 1, y: head.y)
        case .right: newHead = Position(x: head.x + 1, y: head.y)
        }

        if newHead.x < 0 || newHead.x >= gridSize || newHead.y < 0 || newHead.y >= gridSize {
            gameOver()
            return
        }

        if snake.contains(newHead) {
            gameOver()
            return
        }

        snake.insert(newHead, at: 0)

        if newHead == food {
            score += 1
            spawnFood()
        } else {
            snake.removeLast()
        }
    }

    private func gameOver() {
        isGameOver = true
        bestScore = max(bestScore, score)
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Views

struct ContentView: View {
    @State private var game = SnakeGame()
    @State private var foodPulse = false

    var body: some View {
        ZStack {
            // Full-screen gradient background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15),
                         Color(red: 0.1, green: 0.0, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SNAKE")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("swipe to play")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        ScoreBadge(label: "SCORE", value: game.score, color: .cyan)
                        ScoreBadge(label: "BEST", value: game.bestScore, color: .yellow)
                    }
                }
                .padding(.horizontal, 4)

                // Game board
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    let cellSize = side / CGFloat(game.gridSize)

                    ZStack {
                        // Board background with grid
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                            .overlay(
                                GridPattern(gridSize: game.gridSize, cellSize: cellSize)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Neon border
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.green.opacity(0.6), .cyan.opacity(0.3), .purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )

                        // Food glow + food
                        Circle()
                            .fill(.red.opacity(0.3))
                            .frame(width: cellSize * 2.5, height: cellSize * 2.5)
                            .blur(radius: 10)
                            .position(
                                x: CGFloat(game.food.x) * cellSize + cellSize / 2,
                                y: CGFloat(game.food.y) * cellSize + cellSize / 2
                            )

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.red, .orange],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: cellSize * 0.4
                                )
                            )
                            .frame(width: cellSize * 0.75, height: cellSize * 0.75)
                            .shadow(color: .red.opacity(0.8), radius: 6)
                            .scaleEffect(foodPulse ? 1.2 : 0.85)
                            .position(
                                x: CGFloat(game.food.x) * cellSize + cellSize / 2,
                                y: CGFloat(game.food.y) * cellSize + cellSize / 2
                            )

                        // Snake body
                        ForEach(game.snake.indices, id: \.self) { i in
                            let pos = game.snake[i]
                            let isHead = i == 0
                            let progress = CGFloat(i) / max(CGFloat(game.snake.count - 1), 1)

                            RoundedRectangle(cornerRadius: isHead ? cellSize * 0.35 : cellSize * 0.25)
                                .fill(
                                    isHead
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [.white, .cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                    : AnyShapeStyle(
                                        Color(
                                            hue: 0.35 - Double(progress) * 0.1,
                                            saturation: 0.9,
                                            brightness: 1.0 - Double(progress) * 0.4
                                        )
                                    )
                                )
                                .frame(
                                    width: cellSize * (isHead ? 0.92 : 0.82),
                                    height: cellSize * (isHead ? 0.92 : 0.82)
                                )
                                .shadow(color: isHead ? .cyan.opacity(0.6) : .green.opacity(0.3), radius: isHead ? 6 : 2)
                                .position(
                                    x: CGFloat(pos.x) * cellSize + cellSize / 2,
                                    y: CGFloat(pos.y) * cellSize + cellSize / 2
                                )
                        }

                        // Game over overlay
                        if game.isGameOver {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)

                            VStack(spacing: 16) {
                                Text("GAME OVER")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("\(game.score) pts")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Button {
                                    game.reset()
                                    game.start()
                                } label: {
                                    Text("PLAY AGAIN")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 14)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.green, .cyan],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        )
                                }
                                .shadow(color: .green.opacity(0.5), radius: 10)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .aspectRatio(1, contentMode: .fit)

                // Direction hint arrows
                HStack(spacing: 40) {
                    DirectionArrow(symbol: "chevron.left", direction: .left, current: game.direction)
                    VStack(spacing: 20) {
                        DirectionArrow(symbol: "chevron.up", direction: .up, current: game.direction)
                        DirectionArrow(symbol: "chevron.down", direction: .down, current: game.direction)
                    }
                    DirectionArrow(symbol: "chevron.right", direction: .right, current: game.direction)
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    if abs(dx) > abs(dy) {
                        game.changeDirection(dx > 0 ? .right : .left)
                    } else {
                        game.changeDirection(dy > 0 ? .down : .up)
                    }
                }
        )
        .onAppear {
            game.start()
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                foodPulse = true
            }
        }
        .onDisappear {
            game.stop()
        }
    }
}

// MARK: - Components

struct ScoreBadge: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            Text("\(value)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.white.opacity(0.08))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DirectionArrow: View {
    let symbol: String
    let direction: Direction
    let current: Direction

    var isActive: Bool { direction == current }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(isActive ? .cyan : .white.opacity(0.2))
            .shadow(color: isActive ? .cyan.opacity(0.6) : .clear, radius: 6)
            .animation(.easeOut(duration: 0.15), value: current)
    }
}

struct GridPattern: View {
    let gridSize: Int
    let cellSize: CGFloat

    var body: some View {
        Canvas { context, size in
            for i in 0...gridSize {
                let pos = CGFloat(i) * cellSize
                var hPath = Path()
                hPath.move(to: CGPoint(x: 0, y: pos))
                hPath.addLine(to: CGPoint(x: size.width, y: pos))
                context.stroke(hPath, with: .color(.white.opacity(0.04)), lineWidth: 0.5)

                var vPath = Path()
                vPath.move(to: CGPoint(x: pos, y: 0))
                vPath.addLine(to: CGPoint(x: pos, y: size.height))
                context.stroke(vPath, with: .color(.white.opacity(0.04)), lineWidth: 0.5)
            }
        }
    }
}

#Preview {
    ContentView()
}
