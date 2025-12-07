# Quick Start Guide

## 60-Second Setup

```bash
# 1. Install Xcode Command Line Tools (if needed)
xcode-select --install

# 2. Clone and build
git clone https://github.com/apouchet/snake-metal.git
cd snake-metal
make

# 3. Play!
./SnakeMetal
```

## Controls

### Movement
- **↑ ↓ ← →** - Arrow keys
- **Q/W** - Move up
- **A** - Move left
- **S** - Move down
- **D** - Move right

### Game Control
- **Enter** or **Space** - Start game / Pause / Resume

## How to Play

1. **Start**: Press Enter or Space from the menu
2. **Eat Food**: Guide the green snake to the red food
3. **Grow**: Snake gets longer with each food eaten
4. **Score**: +10 points per food
5. **Avoid**: Don't hit walls or your own tail
6. **Compete**: Try to beat your high score!

## Tips

- Snake speeds up as you score more points
- Plan ahead - you can't reverse direction
- Use the full grid to avoid trapping yourself
- Pause anytime with Space or Enter

## Full Screen

- Click the green button (macOS) or
- Menu Bar → View → Enter Full Screen or
- Press Control+Command+F

## Troubleshooting

**"Metal is not supported"**
- Your Mac is too old (pre-2012)
- Update macOS to 10.13 or later

**Build fails**
- Install Xcode Command Line Tools: `xcode-select --install`

**Game won't start**
- Make sure you're on macOS (not Linux/Windows)
- Metal only works on macOS

For more help, see BUILD.md
