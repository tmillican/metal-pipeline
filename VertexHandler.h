#include <Metal/Metal.h>

#include "RenderSource.h"

@interface VertexHandler : NSObject

@property MTLVertexDescriptor *vertexDescriptor;

- (VertexHandler *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source;

- (void)handleWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder;

@end
