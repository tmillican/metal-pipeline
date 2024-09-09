#import "RenderSource.h"

@implementation RenderSource

static Vertex VERTICES[4] = {
  { { -1, -1, 0 }, { 1, 1, 0 } },
  { { -1, 1, 0 }, { 1, 0, 0 } },
  { { 1, -1, 0 }, { 0, 1, 0 } },
  { { 1, 1, 0 }, { 0, 0, 1 } }
};

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
    _vertexIndexCount = 6;
    _clearColor = CLEAR_COLOR;
  }
  return self;
}

- (void)tick
{
}

@end
