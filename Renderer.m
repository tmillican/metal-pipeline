#import <Metal/Metal.h>

#import "Renderer.h"

@implementation Renderer {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  id<MTLRenderPipelineState> _pipelineState;
  id<MTLBuffer> _vertexBuffer;
  id<MTLBuffer> _vertexIndexBuffer;
  RenderSource *_source;
}

static const NSUInteger VERTEX_BUFFER_CAPACITY = 40960;
static const NSUInteger VERTEX_INDEX_BUFFER_CAPACITY = 40960;

- (Renderer *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source
{
  self = [super init];
  if (self != nil) {
    _source = source;
    _device = device;
    NSError* error = nil;
    NSString* shaderSource = [NSString stringWithContentsOfFile:@"shader.metal"
                              encoding:NSUTF8StringEncoding
                              error:&error];
    id<MTLLibrary> library = [_device newLibraryWithSource:shaderSource options:nil error:&error];
    if (!library) {
      NSLog(@"Failed to create library, error: %@", error);
      return nil;
    }

    MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexDescriptor = [self buildVertexDescriptor];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_shader"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_shader"];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!_pipelineState) {
      NSLog(@"Failed to create pipeline state, error: %@", error);
      return nil;
    }

    _commandQueue = [_device newCommandQueue];
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
  return self;
}

- (MTLVertexDescriptor *)buildVertexDescriptor
{
  // You don't _have_ to use a vertex descriptor, but doing so lets you
  // use [[ stage_in ]] in the vertex shader. This siplifies the shader
  // by letting Metal step over vertices for you. Instead of a vertex
  // buffer argument and a vertex index argument, the shader just gets
  // a dereferenced Vertex struct.
  //
  // It can also do some type promotion for you automatically. Ex: sending
  // a float3 on the obj-c side, but receiving a float4 on the shader side.
  // You can also reorder the vertex struct fields on the shader side by
  // using the [[ attribute(n) ]] specifier.
  //
  // The sizes and offsets need to precisely match the struct in Vertex.h
  MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
  NSUInteger offset = 0;

  // Vertex.position
  MTLVertexAttributeDescriptor *positionDescriptor = [[MTLVertexAttributeDescriptor alloc] init];
  positionDescriptor.format = MTLVertexFormatFloat3;
  positionDescriptor.offset = offset;
  // Goes in buffer(0)
  positionDescriptor.bufferIndex = 0;
  // And is tagged as attribute(0)
  [vertexDescriptor.attributes setObject:positionDescriptor atIndexedSubscript:0];
  offset += sizeof(float) * 3;

  // Vertex.color
  MTLVertexAttributeDescriptor *colorDescriptor = [[MTLVertexAttributeDescriptor alloc] init];
  colorDescriptor.format = MTLVertexFormatFloat3;
  colorDescriptor.offset = offset;
  // Also goes in buffer(0)
  colorDescriptor.bufferIndex = 0;
  // And is tagged as attribute(1)
  [vertexDescriptor.attributes setObject:colorDescriptor atIndexedSubscript:1];

  // The layout descriptor tells Metal what the stride of the vertex data is,
  // and when it should step to the next vertex.
  MTLVertexBufferLayoutDescriptor *layoutDescriptor = [[MTLVertexBufferLayoutDescriptor alloc] init];
  layoutDescriptor.stride = sizeof(Vertex);
  // These are the defaults:
  //
  // layoutDescriptor.stepFunction = MTLVertexStepFunctionPerVertex;
  // layoutDescriptor.stepRate = 1;
  //
  // If you're using an instanced vertex shader, you'll need to use
  // MTLVertexStepFunctionPerInstance instead.
  [vertexDescriptor.layouts setObject:layoutDescriptor atIndexedSubscript:0];
  return vertexDescriptor;
}

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

  [self loadGeometry];
  // The vertex buffer will occupy binding point [[ buffer(0) ]]
  [commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];

  [commandEncoder
   drawIndexedPrimitives:MTLPrimitiveTypeTriangle
   indexCount: _source.vertexIndexCount
   indexType: MTLIndexTypeUInt32
   indexBuffer: _vertexIndexBuffer
   indexBufferOffset: 0];
  [commandEncoder endEncoding];
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
}

- (void)loadGeometry
{
  memcpy(_vertexBuffer.contents, _source.vertices.bytes, _source.vertices.length);
  memcpy(_vertexIndexBuffer.contents, _source.vertexIndices.bytes, _source.vertexIndices.length);
}

@end
