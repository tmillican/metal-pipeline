#import <Cocoa/Cocoa.h>

#import "AppDelegate.h"

int main(int argc, const char * argv[])
{
  AppDelegate *appDelegate = [[AppDelegate alloc] init];
  [NSApplication sharedApplication];
  NSApp.delegate = appDelegate;
  [NSApp run];
}
