#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <sys/types.h>

#import "Renderer.h"
#import "VertexHandler.h"
#import "UniformsHandler.h"
#import "TextureHandler.h"
#import "PipelineHandler.h"

@implementation Renderer {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  RenderSource *_source;
  VertexHandler *_vertexHandler;
  UniformsHandler *_uniformsHandler;
  TextureHandler *_textureHandler;
  PipelineHandler *_pipelineHandler;

  bool _firstPass;
}

+ (NSUInteger)getTextureSlotCount
{
  return 4;
}

- (Renderer *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source
{
  self = [super init];
  if (!self) return self;
  _firstPass = true;
  _source = source;
  _device = device;
  _vertexHandler = [[VertexHandler alloc] initWithDevice:_device source:_source];
  _uniformsHandler = [[UniformsHandler alloc] initWithDevice:_device source:_source];
  _textureHandler = [[TextureHandler alloc] initWithDevice:_device source:_source];
  _pipelineHandler = [[PipelineHandler alloc] initWithDevice:_device
                      source:_source
                      vertexDescriptor:_vertexHandler.vertexDescriptor];
  _commandQueue = [_device newCommandQueue];

  return self;
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

  [_source tick];

  [commandEncoder setRenderPipelineState:[_pipelineHandler getPipelineState]];
  [_textureHandler handleWithCommandEncoder:commandEncoder];
  [_uniformsHandler handleWithCommandEncoder:commandEncoder];
  [_vertexHandler handleWithCommandEncoder:commandEncoder];

  [commandEncoder endEncoding];
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
  _firstPass = false;
}

@end
