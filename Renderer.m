#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <sys/types.h>

#import "Renderer.h"
#import "TextureHandler.h"
#import "VertexHandler.h"
#import "uniform_types.h"

@implementation Renderer {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  id<MTLRenderPipelineState> _pipelineState;
  NSMutableData * _uniformsBuffer;
  RenderSource *_source;
  TextureHandler *_textureHandler;
  VertexHandler *_vertexHandler;

  bool _firstPass;
}

static const NSUInteger UNIFORMS_BUFFER_CAPACITY = 4096;

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
    _textureHandler = [[TextureHandler alloc] initWithDevice:_device source:_source];
    _vertexHandler = [[VertexHandler alloc] initWithDevice:_device source:_source];
    _commandQueue = [_device newCommandQueue];

    id library = [self initializeShaders];
    if (!library) return nil;

    [self initializePipeline:library];
    if (!_pipelineState) return nil;

    _uniformsBuffer = [NSMutableData dataWithLength:UNIFORMS_BUFFER_CAPACITY];
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

- (void)loadAndBindUniforms:(id<MTLRenderCommandEncoder>)commandEncoder
{
  void *buffer = _uniformsBuffer.mutableBytes;
  size_t offset = 0;
  for (size_t i = 0; i < _source.uniformDescriptors.count; i++) {
    id descriptor = _source.uniformDescriptors[i];
    enum UniformType type = ((NSNumber *)descriptor[@"type"]).intValue;
    int intValue;
    float floatValue;
    switch (type) {
    case UniformTypeInt:
      intValue = ((NSNumber *)descriptor[@"value"]).intValue;
      memcpy(buffer + offset, &intValue, sizeof(int));
      offset += sizeof(int);
      break;
    case UniformTypeFloat:
      floatValue = ((NSNumber *)descriptor[@"value"]).floatValue;
      memcpy(buffer + offset, &floatValue, sizeof(float));
      offset += sizeof(float);
      break;
    default:
      NSLog(@"Invalid uniform type in descriptor %lu: %d", i, type);
      break;
    }
  }
  // For data totalling <= 4K, Apple advises using set[Foo]Bytes
  // instead of set[Foo]Buffer
  [commandEncoder setVertexBytes:buffer length:offset atIndex:1];
  [commandEncoder setFragmentBytes:buffer length:offset atIndex:0];
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
  [self loadAndBindUniforms:commandEncoder];

  [_vertexHandler handleWithCommandEncoder:commandEncoder];

  [commandEncoder endEncoding];
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
  _firstPass = false;
}

@end
