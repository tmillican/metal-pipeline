#import <Metal/Metal.h>

#import "RenderSource.h"

@interface TextureHandler : NSObject

- (TextureHandler *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source;

- (void)handleWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder;

@end
