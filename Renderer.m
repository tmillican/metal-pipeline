#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <sys/types.h>

#import "Renderer.h"
#import "VertexHandler.h"
#import "UniformsHandler.h"
#import "TextureHandler.h"

@implementation Renderer {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  id<MTLRenderPipelineState> _pipelineState;
  RenderSource *_source;
  VertexHandler *_vertexHandler;
  UniformsHandler *_uniformsHandler;
  TextureHandler *_textureHandler;

  bool _firstPass;
}

+ (NSUInteger)getTextureSlotCount
{
  return 4;
}

- (Renderer *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source
{
  self = [super init];
  if (self != nil) {
    _firstPass = true;
    _source = source;
    _device = device;
    _vertexHandler = [[VertexHandler alloc] initWithDevice:_device source:_source];
    _uniformsHandler = [[UniformsHandler alloc] initWithDevice:_device source:_source];
    _textureHandler = [[TextureHandler alloc] initWithDevice:_device source:_source];
    _commandQueue = [_device newCommandQueue];

    id library = [self initializeShaders];
    if (!library) return nil;

    [self initializePipeline:library];
    if (!_pipelineState) return nil;
  }
  return self;
}

- (id<MTLLibrary>)initializeShaders
{
  NSError *error;
  NSString* shaderSource = [NSString stringWithContentsOfFile:@"shader.metal"
                            encoding:NSUTF8StringEncoding
                            error:&error];
  id<MTLLibrary> library = [_device newLibraryWithSource:shaderSource options:nil error:&error];
  if (!library) {
    NSLog(@"Failed to create library, error: %@", error);
  }
  return library;
}

- (void)initializePipeline:(id<MTLLibrary>)library
{
  MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineDescriptor.vertexDescriptor = _vertexHandler.vertexDescriptor;
  pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_shader"];
  pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_shader"];
  pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

  NSError* error;
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
  if (!_pipelineState) {
    NSLog(@"Failed to create pipeline state, error: %@", error);
  }
}



// ---[ MTKViewDelegate ] -----------------------------------------------------

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize) size
{

}

- (void)drawInMTKView:(MTKView *)view
{
  [view setClearColor:_source.clearColor];
  id descriptor = view.currentRenderPassDescriptor;
  id drawable = view.currentDrawable;
  id commandBuffer = [_commandQueue commandBuffer];
  id commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
  [commandEncoder setRenderPipelineState:_pipelineState];

  [_source tick];

  [_textureHandler handleWithCommandEncoder:commandEncoder];
  [_uniformsHandler handleWithCommandEncoder:commandEncoder];
  [_vertexHandler handleWithCommandEncoder:commandEncoder];

  [commandEncoder endEncoding];
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
  _firstPass = false;
}

@end
