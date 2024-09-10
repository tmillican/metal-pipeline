#import "VertexHandler.h"
#import "Renderer.h"

@implementation VertexHandler {
  id<MTLDevice> _device;
  RenderSource *_source;
  id<MTLBuffer> _vertexBuffer;
  id<MTLBuffer> _vertexIndexBuffer;
}

static const NSUInteger VERTEX_BUFFER_CAPACITY = 40960;
static const NSUInteger VERTEX_INDEX_BUFFER_CAPACITY = 40960;

- (VertexHandler *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source
{
  _device = device;
  _source = source;
  _vertexDescriptor = [self buildVertexDescriptor];

  // Storage modes are complicated:
  //
  // https://developer.apple.com/documentation/metal/resource_fundamentals/setting_resource_storage_modes?language=objc
  //
  // On Intel Macs, only, you can use MTLStorageModeManaged which takes
  // advantage of dedicated VRAM, but it's also more headache since you have to
  // manually inform the GPU of when you've modified a range of data in the
  // buffer.
  //
  // MTLResourceCPUCacheModeWriteCombined will work on anything, and is suitable
  // for buffers that write-only to the CPU.
  _vertexBuffer = [_device newBufferWithLength:VERTEX_BUFFER_CAPACITY
                   options:(MTLResourceCPUCacheModeWriteCombined |
                            MTLStorageModeShared)
                  ];
  _vertexIndexBuffer = [_device newBufferWithLength:VERTEX_INDEX_BUFFER_CAPACITY
                        options:(MTLResourceCPUCacheModeWriteCombined |
                                 MTLStorageModeShared)
                       ];
  return self;
}

- (MTLVertexDescriptor *)buildVertexDescriptor
{
  // You don't _have_ to use a vertex descriptor, but doing so lets you
  // use [[ stage_in ]] in the vertex shader. This simplifies the shader
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

// Loads the vertex data and draws the primitives
- (void)handleWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
{
  // Loads the vertex and vertex index data from the `RenderSource` into their
  // respective `MTLBuffer`s. The vertex data buffer is bound to [[ buffer(0) ]]
  // in the vertex function argument table.
  //
  // The index buffer is only used by the vertex fetch function, so it isn't
  // bound to the argument table.
  memcpy(_vertexBuffer.contents, _source.vertices.bytes, _source.vertices.length);
  memcpy(_vertexIndexBuffer.contents, _source.vertexIndices.bytes, _source.vertexIndices.length);
  [commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];

  [commandEncoder
   drawIndexedPrimitives:MTLPrimitiveTypeTriangle
   indexCount: _source.vertexIndices.length / sizeof(uint32_t)
   indexType: MTLIndexTypeUInt32
   indexBuffer: _vertexIndexBuffer
   indexBufferOffset: 0];
}

@end
