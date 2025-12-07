# Code Documentation

## Architecture Overview

The Snake Metal game is built with a clean separation of concerns:

1. **Game Logic Layer (C)** - Pure C implementation with no dependencies
2. **Rendering Layer (Objective-C + Metal)** - Platform-specific graphics
3. **Shader Layer (Metal Shading Language)** - GPU programs

## File Descriptions

### game.h / game.c

**Purpose**: Pure C implementation of Snake game logic.

**Key Features**:
- No dependencies on rendering or platform code
- Fully testable in isolation
- Grid-based movement system
- Collision detection (walls and self)
- Food spawning algorithm
- High score persistence

**Data Structures**:

```c
typedef struct {
    int x, y;
} Point;

typedef struct {
    Point segments[MAX_SNAKE_LENGTH];
    int length;
    Direction direction;
    Direction next_direction;
} Snake;

typedef struct {
    GameState state;
    Snake snake;
    Point food;
    int score;
    HighScores high_scores;
    float move_timer;
    float move_interval;
} Game;
```

**Key Functions**:

- `game_init()` - Initialize game state, load high scores
- `game_update()` - Update game logic based on delta time
- `game_handle_key()` - Process keyboard input
- `move_snake()` - Core snake movement logic
- `check_collision()` - Detect wall/self collisions
- `spawn_food()` - Place food in valid position
- `high_scores_*()` - Manage persistent high scores

### main.m

**Purpose**: Objective-C wrapper providing Metal rendering and macOS window management.

**Components**:

1. **Renderer Class**
   - Implements `MTKViewDelegate` for rendering callbacks
   - Manages Metal pipeline and buffers
   - Converts game state to vertex data
   - Handles different game states (menu, game, pause, game over)

2. **AppDelegate Class**
   - Creates and manages NSWindow
   - Sets up MTKView for Metal rendering
   - Handles keyboard events
   - Manages application lifecycle

**Rendering Pipeline**:

```
Game State → Vertex Generation → Metal Pipeline → Screen
```

**Vertex Generation**:
- Converts grid positions to pixel coordinates
- Creates triangle pairs for each quad (snake segment, food, UI)
- Assigns colors based on object type
- Builds vertex buffer for GPU

**Key Methods**:

- `loadAssets` - Initialize Metal pipeline and shaders
- `drawInMTKView` - Main render loop (60 FPS)
- `drawRect:vertices:color:` - Helper to create quads
- Event monitor - Captures keyboard input

### shaders.metal

**Purpose**: Metal shading language programs running on GPU.

**Vertex Shader** (`vertex_main`):
- Input: 2D position (pixels) + color
- Process: Convert to normalized device coordinates (-1 to 1)
- Output: 4D position + color

**Fragment Shader** (`fragment_main`):
- Input: Interpolated color from vertex shader
- Output: Final pixel color

**Coordinate Conversion**:
```metal
// Pixel (0,0 to width,height) → NDC (-1,-1 to 1,1)
float2 normalized = (in.position / uniforms.screenSize) * 2.0 - 1.0;
normalized.y = -normalized.y; // Flip Y (Metal has Y up, screen has Y down)
```

## Game Mechanics

### Snake Movement

The snake moves on a discrete grid (30x20 cells). Movement is implemented as:

1. **Timer-Based**: `move_timer` accumulates delta time
2. **Threshold Check**: When timer >= `move_interval`, move once
3. **Direction Queue**: `next_direction` prevents 180° turns
4. **Segment Update**: Each segment takes position of previous segment
5. **Head Update**: New head position based on direction

### Collision Detection

**Wall Collision**:
```c
head.x < 0 || head.x >= GRID_WIDTH || 
head.y < 0 || head.y >= GRID_HEIGHT
```

**Self Collision**:
```c
for (int i = 1; i < snake->length; i++) {
    if (head equals segment[i]) return collision;
}
```

### Food Spawning

Algorithm:
1. Generate random position in grid
2. Check if position overlaps snake
3. If overlap, regenerate (loop)
4. Otherwise, place food

### Scoring System

- **+10 points** per food eaten
- **Snake grows** by 1 segment per food
- **Speed increases** as score increases:
  - Base interval: 150ms
  - Formula: `150ms - (score / 1000)`
  - Minimum: 50ms

### High Scores

**Storage**: Plain text file `high_scores.txt`
**Format**: One score per line, sorted descending
**Capacity**: Top 10 scores
**Persistence**: Auto-save on game over

## Input Handling

### Keyboard Layout

```
Q W           ↑
A S D    or   ←↓→

Q/W = Up
A = Left
S = Down
D = Right
```

**Key Codes** (macOS):
- Arrow Up: 126
- Arrow Down: 125
- Arrow Left: 123
- Arrow Right: 124
- Q: 12
- W: 13
- A: 0
- S: 1
- D: 2
- Enter: 36
- Space: 49

### Input Prevention

**180° Turn Prevention**:
- Cannot go directly from UP to DOWN
- Cannot go directly from LEFT to RIGHT
- Uses `next_direction` buffer to defer direction changes

## Rendering Details

### Color Scheme

- **Snake Head**: RGB(0.2, 0.8, 0.2) - Bright green
- **Snake Body**: RGB(0.1, 0.6, 0.1) - Dark green
- **Food**: RGB(0.9, 0.2, 0.2) - Red
- **Grid Background**: RGB(0.05, 0.05, 0.05) - Nearly black
- **Game Background**: RGB(0, 0, 0) - Black
- **Menu Background**: RGB(0.1, 0.1, 0.15) - Dark blue-gray

### UI Elements

**Menu State**:
- Title area (visual indicator)
- "PLAY" button (centered)
- High scores list (top 5 displayed)

**Game State**:
- Grid border
- Snake segments
- Food item
- Score indicator (visual bars)

**Pause State**:
- Semi-transparent overlay
- Pause indicator

**Game Over State**:
- "GAME OVER" indicator
- Final score display
- Return to menu prompt

### Performance

**Frame Rate**: 60 FPS (V-Sync enabled)
**Vertex Count**: ~600-1000 vertices per frame (varies with snake length and UI)
**Memory**: < 10 MB total
**GPU Load**: Minimal (simple 2D rendering)

## Window Management

### Features

1. **Resizable**: Window can be resized freely
2. **Full Screen**: Native macOS full-screen support
3. **Adaptive Layout**: Game grid centers itself in window
4. **Minimum Size**: None enforced, but game remains playable

### Window Properties

- **Initial Size**: 800x600 pixels
- **Style**: Titled, closable, resizable, miniaturizable
- **Position**: Centered on screen
- **Title**: "Snake Metal"

## Build System

### Makefile Targets

- `make` or `make all`: Build everything
- `make run`: Build and run
- `make clean`: Remove all build artifacts

### Compilation Steps

1. **Compile C Sources**: `clang -c game.c -o game.o`
2. **Compile Objective-C**: `clang -fobjc-arc -c main.m -o main.o`
3. **Compile Shaders**: 
   - `xcrun metal -c shaders.metal -o shaders.air`
   - `xcrun metallib shaders.air -o default.metallib`
4. **Link**: `clang game.o main.o -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore -o SnakeMetal`

### Dependencies

**System Frameworks**:
- Cocoa: Window management, UI
- Metal: Graphics API
- MetalKit: Metal view and utilities
- QuartzCore: Timing and animation

**No External Libraries**: The project has zero external dependencies beyond macOS system frameworks.

## Extending the Game

### Adding New Features

**New Game Modes**:
1. Modify `GameState` enum in `game.h`
2. Add state handling in `game_update()` and `game_handle_key()`
3. Add rendering in `drawInMTKView:`

**New Snake Types**:
1. Add fields to `Snake` struct
2. Modify `move_snake()` logic
3. Update rendering colors/patterns

**Power-ups**:
1. Add `PowerUp` struct similar to `Point`
2. Implement spawning logic like food
3. Add collision detection
4. Modify snake behavior in `move_snake()`

### Testing

**Unit Testing Game Logic**:
```c
// game.c is pure C with no dependencies
// Can be tested with any C testing framework

void test_snake_movement() {
    Game game;
    game_init(&game);
    game_start(&game);
    // ... test assertions
}
```

**Integration Testing**:
- Test on real macOS device
- Verify all key combinations
- Test window resize/full-screen
- Verify high score persistence

## Performance Optimization

Current optimizations:
- Single vertex buffer for all geometry
- Minimal state changes per frame
- Efficient grid-based collision detection
- No dynamic allocations in render loop

Potential improvements:
- Texture atlas for UI elements
- Instanced rendering for snake segments
- Compute shader for collision detection (overkill for this game)

## Platform Specifics

### macOS Requirements

- **Minimum**: macOS 10.13 (High Sierra)
- **Metal**: Required (all Macs 2012+)
- **Architecture**: Universal (Apple Silicon + Intel)

### Metal API Version

- Uses Metal 2.0 features
- Compatible with all Metal-capable Macs
- Shaders use MSL 2.0

## Security Considerations

- **File I/O**: Only writes to `high_scores.txt` in working directory
- **Input Validation**: Key codes validated before use
- **Memory Safety**: Fixed-size arrays, no dynamic allocation
- **Integer Overflow**: Score limited by game design
- **Buffer Overflow**: All array accesses bounds-checked

## Known Limitations

1. **Text Rendering**: Uses simple rectangles instead of real text (for simplicity)
2. **Audio**: No sound effects (out of scope)
3. **Networking**: No multiplayer (out of scope)
4. **Customization**: No settings/preferences UI
5. **Themes**: Single color scheme

## Future Enhancements

Possible additions:
- Proper text rendering with Core Text
- Sound effects with AVFoundation
- Multiple difficulty levels
- Different grid sizes
- Wall wrapping mode
- Obstacles
- Multiple food types with different values
- Animations and particle effects
- Leaderboard with names
