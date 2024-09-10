#import "RenderSource.h"
#import "uniform_types.h"

@implementation RenderSource {
  unsigned int _tickCount;
  NSMutableArray *_uniformDescriptors;
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

static MTLClearColor CLEAR_COLOR = { 1.0, 0.0, 1.0, 1.0 };

enum UniformDescriptors : size_t {
  UniformScale = 0,
  UniformTex0UDisp = 1,
  UniformTextureSelector = 2,
};

- (RenderSource *)init
{
  self = [super init];
  if (self) {
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

    _uniformDescriptors = [[NSMutableArray alloc] init];
    _uniformDescriptors[UniformScale] = [[NSMutableDictionary alloc] init];
    _uniformDescriptors[UniformScale][@"name"] = @"scale";
    _uniformDescriptors[UniformScale][@"type"] = [NSNumber numberWithInt:UniformTypeFloat];
    _uniformDescriptors[UniformScale][@"value"] = [NSNumber numberWithFloat:0.5];
    _uniformDescriptors[UniformTex0UDisp] = [[NSMutableDictionary alloc] init];
    _uniformDescriptors[UniformTex0UDisp][@"name"] = @"tex0UDisplacement";
    _uniformDescriptors[UniformTex0UDisp][@"type"] = [NSNumber numberWithInt:UniformTypeFloat];
    _uniformDescriptors[UniformTex0UDisp][@"value"] = [NSNumber numberWithFloat:0];
    _uniformDescriptors[UniformTextureSelector] = [[NSMutableDictionary alloc] init];
    _uniformDescriptors[UniformTextureSelector][@"name"] = @"texureSelector";
    _uniformDescriptors[UniformTextureSelector][@"type"] = [NSNumber numberWithInt:UniformTypeFloat];
    _uniformDescriptors[UniformTextureSelector][@"value"] = [NSNumber numberWithInt:0];

    _tickCount = 0;
  }
  return self;
}

- (void)tick
{
  float scale = sin(2 * M_PI * _tickCount / 60) * 0.25 + 0.75;
  _uniformDescriptors[UniformScale][@"value"] = [NSNumber numberWithFloat:scale];
  _uniformDescriptors[UniformTex0UDisp][@"value"] = [NSNumber numberWithFloat:(_tickCount % 60) / 60.0];
  if (_tickCount % 120 == 0) {
    _uniformDescriptors[UniformTextureSelector][@"value"] = [NSNumber numberWithInt:0];
  } else if (_tickCount % 120 == 60) {
    _uniformDescriptors[UniformTextureSelector][@"value"] = [NSNumber numberWithInt:1];
  }
  _tickCount++;
}

@end
