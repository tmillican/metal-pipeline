#import "RenderSource.h"
#import "UniformsHandler.h"

@implementation RenderSource {
  unsigned int _tickCount;
  // The structure of the uniforms only changes when the shader changes, so we
  // can cache and reuse them instead of rebuilding the descriptors every
  // frame.
  NSMutableArray *_uniformsCache;
}

static Vertex VERTICES[4] = {
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

// NOTE: my renderer code asssumes uint32_t when figuring out how many
// indices are in the `vertexIndices` property so that I don't have
// to pass an explicit count.
static uint32_t VERTEX_INDICES[6] = { 0, 1, 2, 1, 2, 3 };

static MTLClearColor CLEAR_COLOR = { 0.5, 0.5, 0.5, 1.0 };

static NSString *SHADER1_PATH = @"shader1.metal";

static NSString *SHADER2_PATH = @"shader2.metal";

- (RenderSource *)init
{
  self = [super init];
  if (!self) return self;

  _shaderPath = @"shader.metal";
  // Wrap the bytes in NSData so we have a length property for the renderer.
  _vertices = [[NSData alloc]
               initWithBytesNoCopy:VERTICES
               length:sizeof(VERTICES)
               freeWhenDone: false];
  _vertexIndices = [[NSData alloc]
                    initWithBytesNoCopy:VERTEX_INDICES
                    length:sizeof(VERTEX_INDICES)
                    freeWhenDone:false];
  _clearColor = CLEAR_COLOR;
  _texturePaths = @[ @"blue.png", @"red.png", [NSNull null], [NSNull null] ];

  _uniformsCache = [[NSMutableArray alloc] init];
  _uniformsCache[0] = [self buildShader1Uniforms];
  _uniformsCache[1] = [self buildShader2Uniforms];

  _uniforms = [[NSMutableArray alloc] init];

  _tickCount = 0;
  return self;
}

- (NSMutableArray *)buildShader1Uniforms
{
  id uniforms = [[NSMutableArray alloc] init];
  uniforms[0] = [[NSMutableDictionary alloc] init];
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
  id uniforms = _uniformsCache[0];
  float scale = sin(2 * M_PI * _tickCount / 60) * 0.25 + 0.75;
  uniforms[0][@"value"] = [NSNumber numberWithFloat:scale];
  uniforms[1][@"value"] = [NSNumber numberWithFloat:(_tickCount % 60) / 60.0];
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
  id uniforms = _uniformsCache[1];
  if (_tickCount % 120 == 0) {
    uniforms[0][@"value"] = [NSNumber numberWithInt:0];
  } else if (_tickCount % 120 == 60) {
    uniforms[0][@"value"] = [NSNumber numberWithInt:1];
  }
  _uniforms = uniforms;
}

@end
