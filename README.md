# Snake Metal

A fully functional Snake game written in C, designed specifically for macOS with Apple Silicon, using the Metal graphics API for rendering.

## Features

- **Pure C Game Logic**: Core game mechanics implemented in C
- **Metal Rendering**: Hardware-accelerated graphics using Apple's Metal API
- **Game States**: Menu, gameplay, pause, and game over states
- **Dual Input Support**: Arrow keys or Q/W/A/S/D for movement
- **High Score Persistence**: Automatically saves and loads top 10 high scores
- **Resizable Window**: Dynamically adapts to window size changes
- **Full Screen Support**: Native macOS full-screen mode
- **V-Sync**: Smooth 60 FPS rendering synchronized with display refresh rate

## Requirements

- macOS (Apple Silicon recommended, but works on Intel Macs too)
- Xcode Command Line Tools (for `clang` and Metal compiler)

## Building

### Quick Start

```bash
make
```

This will:
1. Compile the C game logic
2. Compile the Objective-C Metal wrapper
3. Compile Metal shaders
4. Link everything into the `SnakeMetal` executable

### Running

```bash
./SnakeMetal
```

Or use:
```bash
make run
```

### Cleaning

```bash
make clean
```

## Controls

### Movement
- **Arrow Keys**: Up, Down, Left, Right
- **Q/W**: Up
- **A**: Left  
- **S**: Down
- **D**: Right

### Game Control
- **Enter** or **Space**: 
  - Start game from menu
  - Pause/unpause during gameplay
  - Return to menu from game over screen

## Game Mechanics

- Snake starts with length 3 in the center of the grid
- Food spawns randomly on the grid
- Eating food increases score by 10 and grows the snake
- Game speeds up gradually as score increases
- Collision with walls or self-collision ends the game
- High scores are automatically saved to `high_scores.txt`

## Architecture

### Files

- **game.h/game.c**: Pure C game logic (snake movement, collision detection, scoring)
- **main.m**: Objective-C wrapper for Metal rendering and macOS window management
- **shaders.metal**: Metal shading language vertex and fragment shaders
- **Makefile**: Build configuration

### Technical Details

- **Grid Size**: 30x20 cells
- **Cell Size**: 25 pixels
- **Update Rate**: 150ms per move (speeds up with score)
- **Rendering**: 60 FPS with V-Sync
- **Coordinate System**: Pixel coordinates converted to normalized device coordinates in vertex shader

## Project Structure

```
snake-metal/
├── game.h              # Game logic header
├── game.c              # Game logic implementation
├── main.m              # Metal rendering and window management
├── shaders.metal       # Metal shaders (vertex/fragment)
├── Makefile           # Build system
└── README.md          # This file
```

## High Scores

High scores are persisted in `high_scores.txt` in the current directory. The file stores up to 10 scores in descending order. Delete the file to reset high scores.

## Development

The project follows a clean separation between:
- **Game Logic (C)**: Pure C code in `game.c` with no dependencies on Metal or Cocoa
- **Rendering Layer (Objective-C)**: Metal setup, window management, and rendering in `main.m`
- **Shaders (Metal)**: GPU programs for efficient 2D quad rendering

This architecture makes the game logic easily testable and portable while leveraging Metal for optimal rendering performance.

## License

This project is provided as-is for educational and entertainment purposes.
