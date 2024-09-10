#import "UniformsHandler.h"

@implementation UniformsHandler {
  id<MTLDevice> _device;
  RenderSource *_source;
  id<MTLBuffer> _uniformsBuffer;
}

static const NSUInteger UNIFORMS_BUFFER_CAPACITY = 4096;

- (UniformsHandler *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source;
{
  self = [super init];
  if (!self) return self;

  _device = device;
  _source = source;
  _uniformsBuffer = [_device newBufferWithLength:UNIFORMS_BUFFER_CAPACITY
                     options:(MTLResourceCPUCacheModeWriteCombined |
                              MTLStorageModeShared)
                    ];

  return self;
}

- (void)handleWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
{
  // Decode the uniforms for this frame and pack the values in the uniforms
  // buffer.
  void *buffer = _uniformsBuffer.contents;
  size_t offset = 0;
  for (size_t i = 0; i < _source.uniforms.count; i++) {
    id uniform = _source.uniforms[i];
    enum UniformType type = ((NSNumber *)uniform[@"type"]).intValue;
    int intValue;
    float floatValue;
    switch (type) {
    case UniformTypeInt:
      intValue = ((NSNumber *)uniform[@"value"]).intValue;
      memcpy(buffer + offset, &intValue, sizeof(int));
      offset += sizeof(int);
      break;
    case UniformTypeFloat:
      floatValue = ((NSNumber *)uniform[@"value"]).floatValue;
      memcpy(buffer + offset, &floatValue, sizeof(float));
      offset += sizeof(float);
      break;
    default:
      NSLog(@"Invalid uniform type for uniform \"%@\": %d", uniform[@"name"], type);
      break;
    }
  }

  // For the vertex function, [[ buffer(0) ]] is bound to the vertex data,
  // so uniforms will be bound to [[ buffer(1) ]].
  [commandEncoder setVertexBuffer:_uniformsBuffer offset:0 atIndex:1];
  // For the fragment function, we can bind to [[ buffer(0) ]] because
  // unlike the vertex function, the [[ stage_in ]] argument uses some
  // internal buffer managed by Metal.
  [commandEncoder setFragmentBuffer:_uniformsBuffer offset:0  atIndex:0];
}

@end
