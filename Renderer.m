#import <Metal/Metal.h>

#import "Renderer.h"

@implementation Renderer {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  id<MTLRenderPipelineState> _pipelineState;
}

- (Renderer *)initWithDevice:(id<MTLDevice>)device
{
  self = [super init];
  if (self != nil) {
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
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_shader"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_shader"];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!_pipelineState) {
      NSLog(@"Failed to create pipeline state, error: %@", error);
      return nil;
    }
  }
  return self;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize) size
{

}

- (void)drawInMTKView:(MTKView *)view
{

}

@end
