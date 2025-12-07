#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include "game.h"

#define CELL_SIZE 25.0f

// Vertex structure matching shader
typedef struct {
    float position[2];
    float color[4];
} Vertex;

// Uniforms structure matching shader
typedef struct {
    float screenSize[2];
} Uniforms;

@interface Renderer : NSObject <MTKViewDelegate>
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, assign) Game* game;
@property (nonatomic, assign) CFTimeInterval lastFrameTime;
@end

@implementation Renderer {
    id<MTLBuffer> _vertexBuffer;
    id<MTLBuffer> _uniformBuffer;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device game:(Game*)game {
    if (self = [super init]) {
        _device = device;
        _game = game;
        _lastFrameTime = CACurrentMediaTime();
        _commandQueue = [_device newCommandQueue];
        
        [self loadAssets];
    }
    return self;
}

- (void)loadAssets {
    NSError* error = nil;
    
    // Load shader library
    id<MTLLibrary> library = [_device newDefaultLibrary];
    if (!library) {
        NSLog(@"Failed to load default library");
        return;
    }
    
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
    
    // Create pipeline state
    MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // Configure vertex descriptor
    MTLVertexDescriptor* vertexDescriptor = [[MTLVertexDescriptor alloc] init];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[1].offset = sizeof(float) * 2;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.layouts[0].stride = sizeof(Vertex);
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to create pipeline state: %@", error);
    }
    
    // Create buffers
    _vertexBuffer = [_device newBufferWithLength:sizeof(Vertex) * 6 * (MAX_SNAKE_LENGTH + 100)
                                         options:MTLResourceStorageModeShared];
    _uniformBuffer = [_device newBufferWithLength:sizeof(Uniforms) options:MTLResourceStorageModeShared];
}

- (void)drawRect:(CGRect)rect vertices:(Vertex**)vertexPtr color:(float[4])color {
    float x = rect.origin.x;
    float y = rect.origin.y;
    float w = rect.size.width;
    float h = rect.size.height;
    
    Vertex* verts = *vertexPtr;
    
    // Triangle 1
    verts[0] = (Vertex){{x, y}, {color[0], color[1], color[2], color[3]}};
    verts[1] = (Vertex){{x + w, y}, {color[0], color[1], color[2], color[3]}};
    verts[2] = (Vertex){{x, y + h}, {color[0], color[1], color[2], color[3]}};
    
    // Triangle 2
    verts[3] = (Vertex){{x + w, y}, {color[0], color[1], color[2], color[3]}};
    verts[4] = (Vertex){{x + w, y + h}, {color[0], color[1], color[2], color[3]}};
    verts[5] = (Vertex){{x, y + h}, {color[0], color[1], color[2], color[3]}};
    
    *vertexPtr += 6;
}

- (void)drawTextAtX:(float)x y:(float)y text:(const char*)text vertices:(Vertex**)vertexPtr {
    // Simple text rendering using small rectangles (placeholder)
    // In a real implementation, you'd use a proper font rendering system
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    // Update uniforms with new screen size
    Uniforms* uniforms = (Uniforms*)[_uniformBuffer contents];
    uniforms->screenSize[0] = size.width;
    uniforms->screenSize[1] = size.height;
}

- (void)drawInMTKView:(MTKView *)view {
    // Update game
    CFTimeInterval currentTime = CACurrentMediaTime();
    float deltaTime = (float)(currentTime - _lastFrameTime);
    _lastFrameTime = currentTime;
    
    game_update(_game, deltaTime);
    
    // Get render pass descriptor
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (!renderPassDescriptor) {
        return;
    }
    
    // Set background color based on state
    if (_game->state == STATE_MENU || _game->state == STATE_GAME_OVER) {
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.15, 1.0);
    } else {
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    }
    
    // Build vertex data
    Vertex* vertices = (Vertex*)[_vertexBuffer contents];
    Vertex* vertexPtr = vertices;
    int vertexCount = 0;
    
    CGSize viewSize = view.drawableSize;
    float offsetX = (viewSize.width - GRID_WIDTH * CELL_SIZE) / 2.0f;
    float offsetY = (viewSize.height - GRID_HEIGHT * CELL_SIZE) / 2.0f;
    
    if (_game->state == STATE_GAME || _game->state == STATE_PAUSE) {
        // Draw grid background
        float gridColor[4] = {0.05f, 0.05f, 0.05f, 1.0f};
        CGRect gridRect = CGRectMake(offsetX - 2, offsetY - 2, 
                                     GRID_WIDTH * CELL_SIZE + 4, 
                                     GRID_HEIGHT * CELL_SIZE + 4);
        [self drawRect:gridRect vertices:&vertexPtr color:gridColor];
        vertexCount += 6;
        
        // Draw snake
        float headColor[4] = {0.2f, 0.8f, 0.2f, 1.0f};
        float bodyColor[4] = {0.1f, 0.6f, 0.1f, 1.0f};
        
        for (int i = 0; i < _game->snake.length; i++) {
            float x = offsetX + _game->snake.segments[i].x * CELL_SIZE + 1;
            float y = offsetY + _game->snake.segments[i].y * CELL_SIZE + 1;
            CGRect rect = CGRectMake(x, y, CELL_SIZE - 2, CELL_SIZE - 2);
            [self drawRect:rect vertices:&vertexPtr color:(i == 0 ? headColor : bodyColor)];
            vertexCount += 6;
        }
        
        // Draw food
        float foodColor[4] = {0.9f, 0.2f, 0.2f, 1.0f};
        float fx = offsetX + _game->food.x * CELL_SIZE + 1;
        float fy = offsetY + _game->food.y * CELL_SIZE + 1;
        CGRect foodRect = CGRectMake(fx, fy, CELL_SIZE - 2, CELL_SIZE - 2);
        [self drawRect:foodRect vertices:&vertexPtr color:foodColor];
        vertexCount += 6;
        
        // Draw score
        float scoreColor[4] = {1.0f, 1.0f, 1.0f, 1.0f};
        float scoreY = offsetY - 40;
        float scoreX = offsetX;
        
        // Draw simple score display (as colored rectangles)
        for (int i = 0; i < (_game->score / 10) && i < 50; i++) {
            CGRect scoreRect = CGRectMake(scoreX + i * 15, scoreY, 10, 20);
            [self drawRect:scoreRect vertices:&vertexPtr color:scoreColor];
            vertexCount += 6;
        }
        
        // Draw pause overlay
        if (_game->state == STATE_PAUSE) {
            float overlayColor[4] = {0.0f, 0.0f, 0.0f, 0.5f};
            CGRect overlay = CGRectMake(0, 0, viewSize.width, viewSize.height);
            [self drawRect:overlay vertices:&vertexPtr color:overlayColor];
            vertexCount += 6;
            
            // Draw pause text as rectangles
            float pauseColor[4] = {1.0f, 1.0f, 0.0f, 1.0f};
            float centerX = viewSize.width / 2.0f - 60;
            float centerY = viewSize.height / 2.0f - 20;
            
            // P
            [self drawRect:CGRectMake(centerX, centerY, 10, 40) vertices:&vertexPtr color:pauseColor];
            [self drawRect:CGRectMake(centerX, centerY, 30, 10) vertices:&vertexPtr color:pauseColor];
            [self drawRect:CGRectMake(centerX + 20, centerY, 10, 20) vertices:&vertexPtr color:pauseColor];
            [self drawRect:CGRectMake(centerX, centerY + 10, 30, 10) vertices:&vertexPtr color:pauseColor];
            vertexCount += 24;
        }
    } else if (_game->state == STATE_MENU || _game->state == STATE_GAME_OVER) {
        float centerX = viewSize.width / 2.0f;
        float centerY = viewSize.height / 2.0f;
        
        if (_game->state == STATE_GAME_OVER) {
            // Draw "GAME OVER" indication
            float gameOverColor[4] = {1.0f, 0.0f, 0.0f, 1.0f};
            CGRect gameOverRect = CGRectMake(centerX - 100, centerY - 150, 200, 40);
            [self drawRect:gameOverRect vertices:&vertexPtr color:gameOverColor];
            vertexCount += 6;
            
            // Draw final score
            float scoreColor[4] = {1.0f, 1.0f, 0.0f, 1.0f};
            CGRect scoreRect = CGRectMake(centerX - 80, centerY - 90, 160, 30);
            [self drawRect:scoreRect vertices:&vertexPtr color:scoreColor];
            vertexCount += 6;
        }
        
        // Draw "PLAY" button
        float playColor[4] = {0.2f, 0.6f, 0.9f, 1.0f};
        CGRect playButton = CGRectMake(centerX - 80, centerY, 160, 50);
        [self drawRect:playButton vertices:&vertexPtr color:playColor];
        vertexCount += 6;
        
        // Draw high scores title
        float titleColor[4] = {0.9f, 0.9f, 0.9f, 1.0f};
        CGRect titleRect = CGRectMake(centerX - 100, centerY + 80, 200, 30);
        [self drawRect:titleRect vertices:&vertexPtr color:titleColor];
        vertexCount += 6;
        
        // Draw high scores
        float scoreColor[4] = {0.7f, 0.7f, 0.7f, 1.0f};
        for (int i = 0; i < _game->high_scores.count && i < 5; i++) {
            float y = centerY + 120 + i * 35;
            
            // Draw score as bars
            int score = _game->high_scores.scores[i];
            int bars = (score / 10) > 20 ? 20 : (score / 10);
            for (int j = 0; j < bars; j++) {
                CGRect scoreBar = CGRectMake(centerX - 100 + j * 10, y, 8, 25);
                [self drawRect:scoreBar vertices:&vertexPtr color:scoreColor];
                vertexCount += 6;
            }
        }
    }
    
    // Create command buffer and encoder
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [encoder setVertexBuffer:_uniformBuffer offset:0 atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertexCount];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) NSWindow* window;
@property (strong, nonatomic) MTKView* mtkView;
@property (strong, nonatomic) Renderer* renderer;
@property (assign, nonatomic) Game game;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Initialize game
    game_init(&_game);
    
    // Create window
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    NSWindowStyleMask style = NSWindowStyleMaskTitled | 
                              NSWindowStyleMaskClosable | 
                              NSWindowStyleMaskResizable |
                              NSWindowStyleMaskMiniaturizable;
    
    _window = [[NSWindow alloc] initWithContentRect:frame
                                          styleMask:style
                                            backing:NSBackingStoreBuffered
                                              defer:NO];
    
    [_window setTitle:@"Snake Metal"];
    [_window center];
    
    // Enable full screen
    [_window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    
    // Create Metal view
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) {
        NSLog(@"Metal is not supported on this device");
        [NSApp terminate:nil];
        return;
    }
    
    _mtkView = [[MTKView alloc] initWithFrame:frame device:device];
    _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    _mtkView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    _mtkView.enableSetNeedsDisplay = NO;
    _mtkView.preferredFramesPerSecond = 60;
    
    // Create renderer
    _renderer = [[Renderer alloc] initWithDevice:device game:&_game];
    _mtkView.delegate = _renderer;
    
    [_window setContentView:_mtkView];
    [_window makeKeyAndOrderFront:nil];
    [_window makeFirstResponder:_mtkView];
    
    // Set up key event monitoring
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent*(NSEvent* event) {
        unsigned short keyCode = [event keyCode];
        
        // Check if it's an arrow key
        bool isArrow = (keyCode >= 123 && keyCode <= 126);
        
        game_handle_key(&self->_game, keyCode, isArrow);
        
        return event;
    }];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication* app = [NSApplication sharedApplication];
        AppDelegate* delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app activateIgnoringOtherApps:YES];
        [app run];
    }
    return 0;
}
