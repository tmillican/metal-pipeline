#import "RenderSource.h"

@implementation RenderSource

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
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
  },
  {
    { 1, -1, 0 },
    { 0, 1, 0 },
    { 1, 0 },
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
  },
  {
    { 1, 1, 0 },
    { 0, 0, 1 },
    { 1, 1 },
    { 0, 0 },
    { 0, 0 },
    { 0, 0 },
  }
};

// NOTE: my renderer code asssumes uint32_t when figuring out how many
// indices are in the `vertexIndices` property so that I don't have
// to pass an explicit count.
static uint32_t VERTEX_INDICES[6] = { 0, 1, 2, 1, 2, 3 };

static MTLClearColor CLEAR_COLOR = { 1.0, 0.0, 1.0, 1.0 };

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
    _texturePaths = @[ @"blue.png", [NSNull null], [NSNull null], [NSNull null] ];
  }
  return self;
}

- (void)tick
{
}

@end
