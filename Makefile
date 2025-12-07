# Snake Metal - Makefile for macOS (Apple Silicon)

# Compiler and flags
CC = clang
CFLAGS = -Wall -Wextra -std=c11 -O2
OBJC_FLAGS = -fobjc-arc
FRAMEWORKS = -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore

# Source files
C_SOURCES = game.c
OBJC_SOURCES = main.m
SHADER_SOURCES = shaders.metal

# Object files
C_OBJECTS = $(C_SOURCES:.c=.o)
OBJC_OBJECTS = $(OBJC_SOURCES:.m=.o)
SHADER_OUTPUT = default.metallib

# Output executable
TARGET = SnakeMetal

# Default target
all: $(TARGET)

# Compile C sources
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Compile Objective-C sources
%.o: %.m
	$(CC) $(CFLAGS) $(OBJC_FLAGS) -c $< -o $@

# Compile Metal shaders
$(SHADER_OUTPUT): $(SHADER_SOURCES)
	xcrun -sdk macosx metal -c $(SHADER_SOURCES) -o shaders.air
	xcrun -sdk macosx metallib shaders.air -o $(SHADER_OUTPUT)

# Link everything
$(TARGET): $(C_OBJECTS) $(OBJC_OBJECTS) $(SHADER_OUTPUT)
	$(CC) $(C_OBJECTS) $(OBJC_OBJECTS) $(FRAMEWORKS) -o $(TARGET)
	@echo "Build complete! Run with: ./$(TARGET)"

# Clean build artifacts
clean:
	rm -f $(C_OBJECTS) $(OBJC_OBJECTS) $(TARGET) $(SHADER_OUTPUT) shaders.air high_scores.txt

# Run the game
run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
