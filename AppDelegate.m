#import "AppDelegate.h"

@implementation AppDelegate {
  NSWindow *_window;
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification
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
  [_window makeKeyAndOrderFront:nil];
  [_window orderFrontRegardless];
  [_window makeMainWindow];
  [_window becomeMainWindow];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
  return true;
}

@end
