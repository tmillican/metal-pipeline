#import <Metal/Metal.h>

#import "RenderSource.h"

@interface PipelineHandler : NSObject

- (PipelineHandler *)initWithDevice:(id<MTLDevice>)device
source:(RenderSource *)source
vertexDescriptor:(MTLVertexDescriptor *)vertexDescriptor;

- (id<MTLRenderPipelineState>)getPipelineState;

@end
