#ifndef GAME_H
#define GAME_H

#include <stdbool.h>

#define GRID_WIDTH 30
#define GRID_HEIGHT 20
#define MAX_SNAKE_LENGTH (GRID_WIDTH * GRID_HEIGHT)
#define MAX_HIGH_SCORES 10

typedef enum {
    DIR_UP,
    DIR_DOWN,
    DIR_LEFT,
    DIR_RIGHT
} Direction;

typedef enum {
    STATE_MENU,
    STATE_GAME,
    STATE_PAUSE,
    STATE_GAME_OVER
} GameState;

typedef struct {
    int x;
    int y;
} Point;

typedef struct {
    Point segments[MAX_SNAKE_LENGTH];
    int length;
    Direction direction;
    Direction next_direction;
} Snake;

typedef struct {
    int scores[MAX_HIGH_SCORES];
    int count;
} HighScores;

typedef struct {
    GameState state;
    Snake snake;
    Point food;
    int score;
    HighScores high_scores;
    float move_timer;
    float move_interval;
} Game;

// Game functions
void game_init(Game* game);
void game_update(Game* game, float delta_time);
void game_handle_key(Game* game, int key_code, bool is_arrow);
void game_reset(Game* game);
void game_start(Game* game);
void game_pause(Game* game);
void game_resume(Game* game);

// High score functions
void high_scores_load(HighScores* hs);
void high_scores_save(const HighScores* hs);
void high_scores_add(HighScores* hs, int score);

#endif // GAME_H
