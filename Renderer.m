#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <sys/types.h>

#import "Renderer.h"
#import "Vertex.h"

@implementation Renderer {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  id<MTLRenderPipelineState> _pipelineState;
  id<MTLBuffer> _vertexBuffer;
  id<MTLBuffer> _vertexIndexBuffer;
  MTKTextureLoader* _textureLoader;
  NSMutableDictionary<NSString*, id<MTLTexture>> *_textureCache;
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
    _commandQueue = [_device newCommandQueue];

    id library = [self initializeShaders];
    if (!library) return nil;

    [self initializePipeline:library];
    if (!_pipelineState) return nil;

    if (![self initializeTextureLoader]) return nil;

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

- (bool)initializeTextureLoader
{
  _textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
  id emptyTexture = [self loadTextureFromDisk:@"1px-transparent.png"];
  if (!emptyTexture) return false;
  _textureCache = [[NSMutableDictionary alloc] init];
  _textureCache[@"EMPTY_TEXTURE"] = emptyTexture;
  return true;
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
  for (uint i = 0; i < TEXTURE_SLOTS_COUNT; i++) {
    MTLVertexAttributeDescriptor *textCoordsDescriptor = [[MTLVertexAttributeDescriptor alloc] init];
    textCoordsDescriptor.format = MTLVertexFormatFloat2;
    textCoordsDescriptor.offset = offset;
    textCoordsDescriptor.bufferIndex = 0;
    // Texture coords will be tagged as [[ attribute(2) ]] .. [[ attribute(TEXTURE_SLOTS_COUNT + 2) ]]
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

- (id<MTLTexture>)loadTextureFromDisk:(NSString*)path
{
  // This formatting is whack -- blame SourceKit lsp.
  NSDictionary<NSString *, id> *options = @ {
    // This is suitable for texures that are write-only to the CPU.
MTKTextureLoaderOptionTextureCPUCacheMode:
    [[NSNumber alloc] initWithUnsignedInt:MTLCPUCacheModeWriteCombined],
MTKTextureLoaderOptionOrigin:
    MTKTextureLoaderOriginBottomLeft,
  };
  NSError *error;
  id<MTLTexture> texture = [_textureLoader
                            newTextureWithContentsOfURL:[NSURL fileURLWithPath:path]
                            options:options
                            error:&error
                           ];
  if (!texture) {
    NSLog(@"Error loading texture '%@': %@", path, error);
  }
  return texture;
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


// Loads the textures specified by `RenderSource.texturePaths`, either from
// cache or disk and binds them to entries in the texture argument table.
- (void)loadAndBindTextures:(id<MTLRenderCommandEncoder>)commandEncoder
{
  for (size_t i = 0; i < TEXTURE_SLOTS_COUNT; i++) {
    id p = _source.texturePaths[i];
    if (p == [NSNull null]) {
      [commandEncoder setFragmentTexture:_textureCache[@"EMPTY_TEXTURE"] atIndex: i];
      continue;
    }
    NSString *texturePath = (NSString *)p;
    id<MTLTexture> cachedTexture = _textureCache[texturePath];
    if (cachedTexture) {
      [commandEncoder setFragmentTexture:cachedTexture atIndex:i];
      continue;
    }
    id<MTLTexture> texture = [self loadTextureFromDisk:texturePath];
    if (texture) {
      // I've not imposed any limits on how much texture data can be
      // cached, but that's an exercise for the reader.
      _textureCache[texturePath] = texture;
      [commandEncoder setFragmentTexture:texture atIndex:i];
    } else {
      [commandEncoder setFragmentTexture:_textureCache[@"EMPTY_TEXTURE"] atIndex: i];
    }
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

  [self loadAndBindVertexData:commandEncoder];
  [self loadAndBindTextures:commandEncoder];

  [commandEncoder
   drawIndexedPrimitives:MTLPrimitiveTypeTriangle
   indexCount: _source.vertexIndices.length / sizeof(uint32_t)
   indexType: MTLIndexTypeUInt32
   indexBuffer: _vertexIndexBuffer
   indexBufferOffset: 0];

  [commandEncoder endEncoding];
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
}

@end
