#import "RenderSource.h"
#import "UniformsHandler.h"
#import "Vertex.h"

@implementation RenderSource {
  unsigned int _tickCount;
  // The structure of the uniforms only changes when the shader changes, so we
  // can cache and reuse them instead of rebuilding the descriptors every
  // frame.
  NSMutableArray *_uniformsCache;
}

static Vertex VERTICES_1[4] = {
  {
    { -1, -1, 0 }, // position
    { 1, 1, 0 }, // color
    { 0, 0 }, // tex0Coords
    { 0, 0 }, // tex1Coords
    { 0, 0 }, // tex2Coords
    { 0, 0 }, // tex3Coords
    // ... etc.
  },
  {
    { -1, 1, 0 },
    { 1, 0, 0 },
    { 0, 1 },
    { 0, 1 },
    { 0, 0 },
    { 0, 0 },
  },
  {
    { 1, -1, 0 },
    { 0, 1, 0 },
    { 1, 0 },
    { 1, 0 },
    { 0, 0 },
    { 0, 0 },
  },
  {
    { 1, 1, 0 },
    { 0, 0, 1 },
    { 1, 1 },
    { 1, 1 },
    { 0, 0 },
    { 0, 0 },
  }
};

static uint32_t VERTEX_INDICES_1[6] = { 0, 1, 2, 1, 2, 3 };
static NSUInteger VERTEX_INDEX_COUNT_1 = 6;

static Vertex VERTICES_2[3] = {
  {
    { -1, -1, 0 },
    { 1, 0, 0 },
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
  },
  {
    { 0, 1, 0 },
    { 0, 1, 0 },
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
  },
  {
    { 1, -1, 0 },
    { 0, 0, 1 },
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
  },
};

static uint32_t VERTEX_INDICES_2[6] = { 0, 1, 2 };
static NSUInteger VERTEX_INDEX_COUNT_2 = 3;

static MTLClearColor CLEAR_COLOR_1 = { 0.5, 0.25, 0.25, 1.0 };

static MTLClearColor CLEAR_COLOR_2 = { 0.0, 0.0, 0.25, 1.0 };

static NSString *SHADER1_PATH = @"shader1.metal";

static NSString *SHADER2_PATH = @"shader2.metal";

- (RenderSource *)init
{
  self = [super init];
  if (!self) return self;

  _texturePaths = @[ @"blue.png", @"red.png", [NSNull null], [NSNull null] ];

  _uniformsCache = [[NSMutableArray alloc] init];
  _uniformsCache[0] = [self buildShader1Uniforms];
  _uniformsCache[1] = [self buildShader2Uniforms];

  _uniforms = [[NSMutableArray alloc] init];

  _tickCount = 0;
  [self shader1];
  return self;
}

- (NSMutableArray *)buildShader1Uniforms
{
  id uniforms = [[NSMutableArray alloc] init];
  uniforms[0] = [[NSMutableDictionary alloc] init];
  // The "name" field of the descriptors isn't used for anything by
  // the renderer; it's just for code clarity.
  uniforms[0][@"name"] = @"scale";
  uniforms[0][@"type"] = [NSNumber numberWithInt:UniformTypeFloat];
  uniforms[0][@"value"] = [NSNumber numberWithFloat:0.5];
  uniforms[1] = [[NSMutableDictionary alloc] init];
  uniforms[1][@"name"] = @"tex0UDisplacement";
  uniforms[1][@"type"] = [NSNumber numberWithInt:UniformTypeFloat];
  uniforms[1][@"value"] = [NSNumber numberWithFloat:0];
  uniforms[2] = [[NSMutableDictionary alloc] init];
  uniforms[2][@"name"] = @"texureSelector";
  uniforms[2][@"type"] = [NSNumber numberWithInt:UniformTypeFloat];
  uniforms[2][@"value"] = [NSNumber numberWithInt:0];
  return uniforms;
}

- (NSMutableArray *)buildShader2Uniforms
{
  id uniforms = [[NSMutableArray alloc] init];
  uniforms[0] = [[NSMutableDictionary alloc] init];
  uniforms[0][@"name"] = @"isColorInverted";
  uniforms[0][@"type"] = [NSNumber numberWithInt:UniformTypeInt];
  uniforms[0][@"value"] = [NSNumber numberWithInt:0];
  return uniforms;
}

- (void)tick
{
  // Swap shaders every 5 seconds / 300 frames
  if (_tickCount % 600 < 300) {
    [self shader1];
  } else {
    [self shader2];
  }
  _tickCount++;
}

- (void)shader1
{
  _shaderPath = SHADER1_PATH;

  // Wrap the bytes in NSData for convenience -- no need for a separate
  // length property this way.
  _vertices = [[NSData alloc]
               initWithBytesNoCopy:VERTICES_1
               length:sizeof(VERTICES_1)
               freeWhenDone: false];
  _vertexIndices = [[NSData alloc]
                    initWithBytesNoCopy:VERTEX_INDICES_1
                    length:sizeof(VERTEX_INDICES_1)
                    freeWhenDone:false];
  _vertexIndexCount = VERTEX_INDEX_COUNT_1;
  _clearColor = CLEAR_COLOR_1;

  id uniforms = _uniformsCache[0];

  // Make the scale swings sinusoidally from 0.5 to 1.0 over 1 second.
  float scale = sin(2 * M_PI * _tickCount / 60) * 0.25 + 0.75;
  uniforms[0][@"value"] = [NSNumber numberWithFloat:scale];

  // The U-axis displacement of the texture linearly increases from 0.0 to 1.0
  // over 1 second, and then begins again from 0.0. I.e. it scrolls left.
  uniforms[1][@"value"] = [NSNumber numberWithFloat:(_tickCount % 60) / 60.0];

  // The selected texture toggles every 2 seconds.
  if (_tickCount % 120 == 0) {
    uniforms[2][@"value"] = [NSNumber numberWithInt:0];
  } else if (_tickCount % 120 == 60) {
    uniforms[2][@"value"] = [NSNumber numberWithInt:1];
  }

  _uniforms = uniforms;
}

- (void)shader2
{
  _shaderPath = SHADER2_PATH;

  _vertices = [[NSData alloc]
               initWithBytesNoCopy:VERTICES_2
               length:sizeof(VERTICES_2)
               freeWhenDone: false];
  _vertexIndices = [[NSData alloc]
                    initWithBytesNoCopy:VERTEX_INDICES_2
                    length:sizeof(VERTEX_INDICES_2)
                    freeWhenDone:false];
  _vertexIndexCount = VERTEX_INDEX_COUNT_2;
  _clearColor = CLEAR_COLOR_2;

  id uniforms = _uniformsCache[1];
  // The color of the primitives inverts every 2 seconds.
  if (_tickCount % 120 == 0) {
    uniforms[0][@"value"] = [NSNumber numberWithInt:0];
  } else if (_tickCount % 120 == 60) {
    uniforms[0][@"value"] = [NSNumber numberWithInt:1];
  }
  _uniforms = uniforms;
}

@end
