#import <MetalKit/MetalKit.h>

#import "AppDelegate.h"
#import "Renderer.h"

@implementation AppDelegate {
  NSWindow *_window;
  Renderer *_renderer;
  RenderSource *_renderSource;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1280, 720)
             styleMask:(NSWindowStyleMaskTitled |
                        NSWindowStyleMaskClosable |
                        NSWindowStyleMaskResizable |
                        NSWindowStyleMaskMiniaturizable)
             backing:NSBackingStoreBuffered
             defer:NO];
  _window.delegate = self;
  [_window setTitle:@"Metal Window"];
  MTKView *metalView = [[MTKView alloc] initWithFrame:NSMakeRect(280, 0, 720, 720)];
  [metalView setDevice:MTLCreateSystemDefaultDevice()];

  _renderSource = [[RenderSource alloc] init];
  _renderer = [[Renderer alloc] initWithDevice:metalView.device source:_renderSource];
  metalView.delegate = _renderer;

  [_window.contentView addSubview:metalView];
  [_window makeKeyAndOrderFront:nil];
  [_window orderFrontRegardless];
  [_window makeMainWindow];
  [_window becomeMainWindow];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
  return true;
}

@end
