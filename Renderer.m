#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <sys/types.h>

#import "Renderer.h"
#import "TextureHandler.h"
#import "Vertex.h"
#import "uniform_types.h"

@implementation Renderer {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  id<MTLRenderPipelineState> _pipelineState;
  id<MTLBuffer> _vertexBuffer;
  id<MTLBuffer> _vertexIndexBuffer;
  NSMutableData * _uniformsBuffer;
  RenderSource *_source;
  TextureHandler *_textureHandler;

  bool _firstPass;
}

static const NSUInteger VERTEX_BUFFER_CAPACITY = 40960;
static const NSUInteger VERTEX_INDEX_BUFFER_CAPACITY = 40960;
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
    _commandQueue = [_device newCommandQueue];

    id library = [self initializeShaders];
    if (!library) return nil;

    [self initializePipeline:library];
    if (!_pipelineState) return nil;

    _uniformsBuffer = [NSMutableData dataWithLength:UNIFORMS_BUFFER_CAPACITY];

    [self initializeVertexBuffers];
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
  pipelineDescriptor.vertexDescriptor = [self buildVertexDescriptor];
  pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_shader"];
  pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_shader"];
  pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

  NSError* error;
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
  if (!_pipelineState) {
    NSLog(@"Failed to create pipeline state, error: %@", error);
  }
}

- (void)initializeVertexBuffers
{

  // Storage modes are complicated:
  // https://developer.apple.com/documentation/metal/resource_fundamentals/setting_resource_storage_modes?language=objc
  //
  // MTLStorageModeManaged is more efficient (and more headache)
  // and uses GPU memory instead of shared system memory, but it's
  // only available on Intel Macs.
  _vertexBuffer = [_device newBufferWithLength:VERTEX_BUFFER_CAPACITY
                   options:(MTLResourceCPUCacheModeWriteCombined |
                            MTLStorageModeShared)
                  ];
  _vertexIndexBuffer = [_device newBufferWithLength:VERTEX_INDEX_BUFFER_CAPACITY
                        options:(MTLResourceCPUCacheModeWriteCombined |
                                 MTLStorageModeShared)
                       ];
}

- (MTLVertexDescriptor *)buildVertexDescriptor
{
  // You don't _have_ to use a vertex descriptor, but doing so lets you
  // use [[ stage_in ]] in the vertex shader. This siplifies the shader
  // in many ways, especially for more sophisticated rendering schemes.
  //
  // There's an excellent explanation of vertex descriptors and how they
  // work under the hood here:
  //
  // https://metalbyexample.com/vertex-descriptors/
  //
  // TLDR: it tells the Metal compiler how to write the vertex fetch
  // function with which it will patch your vertex function.

  // I'm serializing all of the vertex data as a single struct in
  // [[ buffer(0) ]], a.k.a. an inerleaved vertex descriptor, but you
  // can have vertex data in multiple buffers, for instance to step
  // some vertex data at different rates or for different conditions.
  MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
  NSUInteger offset = 0;

  // As an example of automatic type conversions, I'm sending packed float3
  // values for position and color, and these are received as unpacked
  // float4 values per: [x, y, z] -> [x, y, z, 1]

  // Vertex.position -> [[ attribute (0) ]]
  MTLVertexAttributeDescriptor *positionDescriptor = [[MTLVertexAttributeDescriptor alloc] init];
  positionDescriptor.format = MTLVertexFormatFloat3;
  positionDescriptor.offset = offset;
  positionDescriptor.bufferIndex = 0;
  [vertexDescriptor.attributes setObject:positionDescriptor atIndexedSubscript:0];
  offset += sizeof(float) * 3;

  // Vertex.color -> [[ attribute(1) ]]
  MTLVertexAttributeDescriptor *colorDescriptor = [[MTLVertexAttributeDescriptor alloc] init];
  colorDescriptor.format = MTLVertexFormatFloat3;
  colorDescriptor.offset = offset;
  colorDescriptor.bufferIndex = 0;
  [vertexDescriptor.attributes setObject:colorDescriptor atIndexedSubscript:1];
  offset += sizeof(float) * 3;

  // Vertex.texNCoords -> [[ attribute(2 + n) ]]
  for (uint i = 0; i < [Renderer getTextureSlotCount]; i++) {
    MTLVertexAttributeDescriptor *textCoordsDescriptor = [[MTLVertexAttributeDescriptor alloc] init];
    textCoordsDescriptor.format = MTLVertexFormatFloat2;
    textCoordsDescriptor.offset = offset;
    textCoordsDescriptor.bufferIndex = 0;
    // Texture coords will be tagged as [[ attribute(2) ]] .. [[ attribute(slots + 1) ]]
    [vertexDescriptor.attributes setObject:textCoordsDescriptor atIndexedSubscript:2 + i];
    offset += sizeof(float) * 2;
  }

  // Finally, we need layout descriptors for each vertex buffer.
  //
  // The layout descriptor tells Metal what the stride of the vertex buffer is,
  // and when it should step to the next element of that buffer. I'm using a single
  // sruct in a single buffer, a.k.a. an interleaved vertex descriptor, so there's
  // only one layout corresponding to [[ buffer(0) ]].
  MTLVertexBufferLayoutDescriptor *layoutDescriptor = [[MTLVertexBufferLayoutDescriptor alloc] init];
  layoutDescriptor.stride = sizeof(Vertex);
  // As for vertex stepping, the default is a step rate of 1 with per-vertex
  // stepping. That's fine for my purposes of just rendering an arbitrary list
  // of triangles, but you may need different function an stepping if you're
  // using a more elaborate rendering scheme like instanced rendering or tesselation.
  [vertexDescriptor.layouts setObject:layoutDescriptor atIndexedSubscript:0];
  return vertexDescriptor;
}

// Loads the vertex and vertex index data from the `RenderSource` into their
// respective `MTLBuffer`s. The vertex data buffer is bound to [[ buffer(0) ]]
// in the vertex function argument table.
//
// The index buffer is only used by the vertex fetch function, so it isn't
// bound to the argument table.
- (void)loadAndBindVertexData:(id<MTLRenderCommandEncoder>)commandEncoder
{
  memcpy(_vertexBuffer.contents, _source.vertices.bytes, _source.vertices.length);
  memcpy(_vertexIndexBuffer.contents, _source.vertexIndices.bytes, _source.vertexIndices.length);
  // The vertex buffer will be bound to [[ buffer(0) ]] in the argument table
  [commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
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

  [self loadAndBindVertexData:commandEncoder];
  [_textureHandler handleWithCommandEncoder:commandEncoder];
  [self loadAndBindUniforms:commandEncoder];

  [commandEncoder
   drawIndexedPrimitives:MTLPrimitiveTypeTriangle
   indexCount: _source.vertexIndices.length / sizeof(uint32_t)
   indexType: MTLIndexTypeUInt32
   indexBuffer: _vertexIndexBuffer
   indexBufferOffset: 0];

  [commandEncoder endEncoding];
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
  _firstPass = false;
}

@end
