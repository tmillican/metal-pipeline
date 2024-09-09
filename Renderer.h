#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface Renderer : NSObject <MTKViewDelegate>

- (Renderer *)initWithDevice:(id<MTLDevice>)device;

@end
