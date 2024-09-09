#import <MetalKit/MetalKit.h>

#import "AppDelegate.h"
#import "Renderer.h"

@implementation AppDelegate {
  NSWindow *_window;
  Renderer *_renderer;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  NSRect frame = NSMakeRect(0, 0, 1280, 720);
  _window = [[NSWindow alloc] initWithContentRect:frame
             styleMask:(NSWindowStyleMaskTitled |
                        NSWindowStyleMaskClosable |
                        NSWindowStyleMaskResizable |
                        NSWindowStyleMaskMiniaturizable)
             backing:NSBackingStoreBuffered
             defer:NO];
  _window.delegate = self;
  [_window setTitle:@"Metal Window"];
  MTKView *metalView = [[MTKView alloc] initWithFrame:frame];
  [metalView setDevice:MTLCreateSystemDefaultDevice()];
  _renderer = [[Renderer alloc] initWithDevice:metalView.device];
  metalView.delegate = _renderer;
  _window.contentView = metalView;
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
