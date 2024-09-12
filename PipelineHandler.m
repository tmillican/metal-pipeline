#import "PipelineHandler.h"

// Sets up the MTLPipelineState, which includes the vertex and fragment
// function. Whenever the shader path changes, the pipeline state is cached,
// using the shader path as the lookup key, to prevent unncessary shader
// recompilation.
//
// As with the texture cache in TextureHandler, there is no cache limit.

@implementation PipelineHandler {
  id<MTLDevice> _device;
  RenderSource *_source;
  MTLVertexDescriptor *_vertexDescriptor;
  NSMutableDictionary<NSString *, NSObject*> *_cache;
}

- (PipelineHandler *)initWithDevice:(id<MTLDevice>)device
source:(RenderSource *)source
vertexDescriptor:(MTLVertexDescriptor *)vertexDescriptor
{
  self = [super init];
  if (!self) return self;

  _device = device;
  _source = source;
  _vertexDescriptor = vertexDescriptor;
  _cache = [[NSMutableDictionary alloc] init];

  return self;
}

- (id<MTLRenderPipelineState>)getPipelineState
{
  id pipelineState = _cache[_source.shaderPath];
  if (!pipelineState) {

    NSError *error;
    NSString* shaderSource = [NSString stringWithContentsOfFile:_source.shaderPath
                              encoding:NSUTF8StringEncoding
                              error:&error];
    id<MTLLibrary> library = [_device newLibraryWithSource:shaderSource options:nil error:&error];
    if (!library) {
      NSLog(@"Failed to create library, error: %@", error);
    }
    MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexDescriptor = _vertexDescriptor;
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_shader"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_shader"];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!pipelineState) {
      NSLog(@"Failed to create pipeline state, error: %@", error);
    }
    _cache[_source.shaderPath] = pipelineState;
  }
  return pipelineState;
}

@end
