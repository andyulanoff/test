import SwiftUI

// MARK: - Models

enum Direction {
    case up, down, left, right
}

struct Position: Equatable {
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
            pos = Position(x: Int.random(in: 0..<gridSize), y: Int.random(in: 0..<gridSize)
            )
        } while snake.contains(pos)
        food = pos
    }

    func changeDirection(_ newDir: Direction) {
        // Prevent reversing
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

        // Wall collision
        if newHead.x < 0 || newHead.x >= gridSize || newHead.y < 0 || newHead.y >= gridSize {
            isGameOver = true
            return
        }

        // Self collision
        if snake.contains(newHead) {
            isGameOver = true
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

// MARK: - View

struct ContentView: View {
    @State private var game = SnakeGame()

    var body: some View {
        VStack(spacing: 16) {
            Text("Змейка")
                .font(.largeTitle.bold())

            Text("Счёт: \(game.score)")
                .font(.title2)

            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                let cellSize = side / CGFloat(game.gridSize)

                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black)

                    // Food
                    Circle()
                        .fill(Color.red)
                        .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                        .position(
                            x: CGFloat(game.food.x) * cellSize + cellSize / 2,
                            y: CGFloat(game.food.y) * cellSize + cellSize / 2
                        )

                    // Snake
                    ForEach(game.snake.indices, id: \.self) { i in
                        let pos = game.snake[i]
                        let isHead = i == 0
                        RoundedRectangle(cornerRadius: cellSize * 0.2)
                            .fill(isHead ? Color.white : Color.green)
                            .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                            .position(
                                x: CGFloat(pos.x) * cellSize + cellSize / 2,
                                y: CGFloat(pos.y) * cellSize + cellSize / 2
                            )
                    }
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)

            if game.isGameOver {
                VStack(spacing: 12) {
                    Text("Игра окончена!")
                        .font(.title2.bold())
                        .foregroundStyle(.red)

                    Button("Заново") {
                        game.reset()
                        game.start()
                    }
                    .font(.title3)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
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
        }
        .onDisappear {
            game.stop()
        }
    }
}

#Preview {
    ContentView()
}
