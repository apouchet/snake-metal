# Build and Installation Guide

## Prerequisites

This project requires:
- **macOS**: Version 10.13 (High Sierra) or later
- **Xcode Command Line Tools**: Install with `xcode-select --install`
- **Apple Silicon or Intel Mac**: Both are supported, but Apple Silicon is recommended for best performance

## Installation Steps

### 1. Install Xcode Command Line Tools

If you haven't already installed them:

```bash
xcode-select --install
```

This provides the `clang` compiler and Metal shader compiler (`xcrun`).

### 2. Clone the Repository

```bash
git clone https://github.com/apouchet/snake-metal.git
cd snake-metal
```

### 3. Build the Game

```bash
make
```

This command will:
- Compile `game.c` (pure C game logic)
- Compile `main.m` (Objective-C Metal wrapper)
- Compile `shaders.metal` into `default.metallib`
- Link everything into the `SnakeMetal` executable

### 4. Run the Game

```bash
./SnakeMetal
```

Or simply:

```bash
make run
```

## Build Output

After a successful build, you'll have:
- `SnakeMetal` - The executable game
- `default.metallib` - Compiled Metal shaders
- `game.o`, `main.o` - Object files (intermediate)
- `shaders.air` - Intermediate shader file

## Troubleshooting

### "Metal is not supported on this device"

This error means your Mac doesn't support Metal (very old Macs). Metal is available on:
- All Macs from 2012 or later
- macOS 10.13 or later

### "xcrun: error: unable to find utility "metal""

You need to install Xcode Command Line Tools:
```bash
xcode-select --install
```

### "Undefined symbols" errors during linking

Make sure all frameworks are properly linked. The Makefile should include:
```
-framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore
```

### High scores not saving

Ensure the directory is writable. High scores are saved to `high_scores.txt` in the same directory as the executable.

## Clean Build

To remove all build artifacts:

```bash
make clean
```

This removes:
- Object files (`.o`)
- Compiled shaders (`.metallib`, `.air`)
- The executable
- High scores file

## Development

### Project Structure

```
snake-metal/
├── game.h              # Game logic interface
├── game.c              # Game logic implementation (Pure C)
├── main.m              # Metal rendering + Window management (Objective-C)
├── shaders.metal       # GPU shaders (Metal Shading Language)
├── Makefile           # Build configuration
├── README.md          # Main documentation
└── BUILD.md           # This file
```

### Compilation Flags

**C Compilation:**
- `-std=c11`: Use C11 standard
- `-Wall -Wextra`: Enable all warnings
- `-O2`: Optimization level 2

**Objective-C Compilation:**
- `-fobjc-arc`: Enable Automatic Reference Counting

**Linking:**
- `-framework Cocoa`: Window management and UI
- `-framework Metal`: Metal graphics API
- `-framework MetalKit`: Metal convenience classes
- `-framework QuartzCore`: Core animation and timing

### Metal Shader Compilation

Shaders are compiled in two steps:
1. `metal -c shaders.metal -o shaders.air` - Compile to AIR (Apple Intermediate Representation)
2. `metallib shaders.air -o default.metallib` - Link into Metal library

## Platform Support

- **Apple Silicon (M1/M2/M3)**: ✅ Full support, optimal performance
- **Intel Macs (2012+)**: ✅ Full support
- **Older Macs**: ❌ Requires Metal support (macOS 10.13+)
- **Linux/Windows**: ❌ Not supported (Metal is macOS-only)

## Performance

- **Target Frame Rate**: 60 FPS (V-Sync)
- **Resolution**: Adapts to window size
- **GPU Usage**: Minimal (simple 2D rendering)
- **CPU Usage**: Very low (efficient C implementation)

## File Permissions

The game creates `high_scores.txt` in the working directory. Make sure:
- The directory is writable
- You have permission to create files

## Running from Different Locations

The game looks for the Metal shader library (`default.metallib`) in the application's resource bundle or current directory. To run from a different location:

```bash
cd /path/to/your/location
/path/to/snake-metal/SnakeMetal
```

Note: High scores will be saved in the current working directory.
