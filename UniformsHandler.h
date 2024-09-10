#import <Metal/Metal.h>

#import "RenderSource.h"

enum UniformType {
  UniformTypeInt,
  UniformTypeFloat,
};

@interface UniformsHandler : NSObject

- (UniformsHandler *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source;

- (void)handleWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder;

@end
