#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "RenderSource.h"

@interface Renderer : NSObject <MTKViewDelegate>

+ (NSUInteger)getTextureSlotCount;

- (Renderer *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source;

@end
