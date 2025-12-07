#include "game.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#define HIGH_SCORES_FILE "high_scores.txt"

static void spawn_food(Game* game) {
    bool valid = false;
    while (!valid) {
        game->food.x = rand() % GRID_WIDTH;
        game->food.y = rand() % GRID_HEIGHT;
        
        // Check if food spawns on snake
        valid = true;
        for (int i = 0; i < game->snake.length; i++) {
            if (game->snake.segments[i].x == game->food.x &&
                game->snake.segments[i].y == game->food.y) {
                valid = false;
                break;
            }
        }
    }
}

static void snake_init(Snake* snake) {
    snake->length = 3;
    snake->direction = DIR_RIGHT;
    snake->next_direction = DIR_RIGHT;
    
    // Start snake in the middle
    int start_x = GRID_WIDTH / 2;
    int start_y = GRID_HEIGHT / 2;
    
    for (int i = 0; i < snake->length; i++) {
        snake->segments[i].x = start_x - i;
        snake->segments[i].y = start_y;
    }
}

void game_init(Game* game) {
    srand((unsigned int)time(NULL));
    game->state = STATE_MENU;
    game->score = 0;
    game->move_timer = 0.0f;
    game->move_interval = 0.15f; // Move every 150ms
    
    snake_init(&game->snake);
    spawn_food(game);
    high_scores_load(&game->high_scores);
}

void game_reset(Game* game) {
    game->score = 0;
    game->move_timer = 0.0f;
    snake_init(&game->snake);
    spawn_food(game);
}

void game_start(Game* game) {
    game_reset(game);
    game->state = STATE_GAME;
}

void game_pause(Game* game) {
    if (game->state == STATE_GAME) {
        game->state = STATE_PAUSE;
    }
}

void game_resume(Game* game) {
    if (game->state == STATE_PAUSE) {
        game->state = STATE_GAME;
    }
}

static bool check_collision(const Snake* snake) {
    Point head = snake->segments[0];
    
    // Check wall collision
    if (head.x < 0 || head.x >= GRID_WIDTH || head.y < 0 || head.y >= GRID_HEIGHT) {
        return true;
    }
    
    // Check self collision
    for (int i = 1; i < snake->length; i++) {
        if (head.x == snake->segments[i].x && head.y == snake->segments[i].y) {
            return true;
        }
    }
    
    return false;
}

static void move_snake(Game* game) {
    Snake* snake = &game->snake;
    
    // Update direction (prevent 180-degree turns)
    if ((snake->direction == DIR_UP && snake->next_direction != DIR_DOWN) ||
        (snake->direction == DIR_DOWN && snake->next_direction != DIR_UP) ||
        (snake->direction == DIR_LEFT && snake->next_direction != DIR_RIGHT) ||
        (snake->direction == DIR_RIGHT && snake->next_direction != DIR_LEFT)) {
        snake->direction = snake->next_direction;
    }
    
    // Calculate new head position
    Point new_head = snake->segments[0];
    switch (snake->direction) {
        case DIR_UP:    new_head.y--; break;
        case DIR_DOWN:  new_head.y++; break;
        case DIR_LEFT:  new_head.x--; break;
        case DIR_RIGHT: new_head.x++; break;
    }
    
    // Move body segments
    for (int i = snake->length - 1; i > 0; i--) {
        snake->segments[i] = snake->segments[i - 1];
    }
    snake->segments[0] = new_head;
    
    // Check collision
    if (check_collision(snake)) {
        high_scores_add(&game->high_scores, game->score);
        high_scores_save(&game->high_scores);
        game->state = STATE_GAME_OVER;
        return;
    }
    
    // Check food collision
    if (new_head.x == game->food.x && new_head.y == game->food.y) {
        game->score += 10;
        if (snake->length < MAX_SNAKE_LENGTH) {
            snake->length++;
        }
        spawn_food(game);
        
        // Speed up slightly as score increases
        game->move_interval = 0.15f - (game->score / 1000.0f);
        if (game->move_interval < 0.05f) {
            game->move_interval = 0.05f;
        }
    }
}

void game_update(Game* game, float delta_time) {
    if (game->state != STATE_GAME) {
        return;
    }
    
    game->move_timer += delta_time;
    if (game->move_timer >= game->move_interval) {
        game->move_timer = 0.0f;
        move_snake(game);
    }
}

void game_handle_key(Game* game, int key_code, bool is_arrow) {
    // Handle pause/resume
    if (key_code == 36 || key_code == 49) { // Enter or Space
        if (game->state == STATE_MENU) {
            game_start(game);
        } else if (game->state == STATE_GAME) {
            game_pause(game);
        } else if (game->state == STATE_PAUSE) {
            game_resume(game);
        } else if (game->state == STATE_GAME_OVER) {
            game->state = STATE_MENU;
        }
        return;
    }
    
    // Handle direction changes during gameplay
    if (game->state != STATE_GAME) {
        return;
    }
    
    if (is_arrow) {
        switch (key_code) {
            case 126: game->snake.next_direction = DIR_UP; break;    // Up arrow
            case 125: game->snake.next_direction = DIR_DOWN; break;  // Down arrow
            case 123: game->snake.next_direction = DIR_LEFT; break;  // Left arrow
            case 124: game->snake.next_direction = DIR_RIGHT; break; // Right arrow
        }
    } else {
        switch (key_code) {
            case 12:  // Q - Up
            case 13:  // W - Up
                game->snake.next_direction = DIR_UP;
                break;
            case 1:   // S - Down
                game->snake.next_direction = DIR_DOWN;
                break;
            case 0:   // A - Left
                game->snake.next_direction = DIR_LEFT;
                break;
            case 2:   // D - Right
                game->snake.next_direction = DIR_RIGHT;
                break;
        }
    }
}

void high_scores_load(HighScores* hs) {
    hs->count = 0;
    FILE* file = fopen(HIGH_SCORES_FILE, "r");
    if (!file) {
        return;
    }
    
    while (hs->count < MAX_HIGH_SCORES && fscanf(file, "%d", &hs->scores[hs->count]) == 1) {
        hs->count++;
    }
    
    fclose(file);
}

void high_scores_save(const HighScores* hs) {
    FILE* file = fopen(HIGH_SCORES_FILE, "w");
    if (!file) {
        return;
    }
    
    for (int i = 0; i < hs->count; i++) {
        fprintf(file, "%d\n", hs->scores[i]);
    }
    
    fclose(file);
}

void high_scores_add(HighScores* hs, int score) {
    if (score <= 0) {
        return;
    }
    
    // Find insertion position
    int pos = hs->count;
    for (int i = 0; i < hs->count; i++) {
        if (score > hs->scores[i]) {
            pos = i;
            break;
        }
    }
    
    // Insert score
    if (pos < MAX_HIGH_SCORES) {
        // Shift scores down
        int shift_count = hs->count - pos;
        if (hs->count >= MAX_HIGH_SCORES) {
            shift_count = MAX_HIGH_SCORES - pos - 1;
        }
        
        for (int i = shift_count; i > 0; i--) {
            hs->scores[pos + i] = hs->scores[pos + i - 1];
        }
        
        hs->scores[pos] = score;
        
        if (hs->count < MAX_HIGH_SCORES) {
            hs->count++;
        }
    }
}
