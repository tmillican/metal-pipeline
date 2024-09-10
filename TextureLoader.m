#import <MetalKit/MetalKit.h>

#import "TextureLoader.h"

// A simple caching texture loader.
// It has no storage limits.

@implementation TextureLoader {
  NSMutableDictionary<NSString*, id<MTLTexture>> *_cache;
  id<MTLDevice> _device;
  MTKTextureLoader *_loader;
}

- (TextureLoader *)initWithDevice:(id<MTLDevice>)device
{
  self = [super init];
  if (!self) return self;

  _device = device;
  _cache = [[NSMutableDictionary alloc] init];
  _loader = [[MTKTextureLoader alloc] initWithDevice:_device];
  return self;
}

- (id<MTLTexture>)getTextureWithPath:(NSString *)path
{
  if (_cache[path]) return _cache[path];
  id texture = [self loadTextureFromDisk:path];
  if (texture) _cache[path] = texture;
  return texture;
}

- (id<MTLTexture>)loadTextureFromDisk:(NSString*)path
{
  // This formatting is whack -- blame SourceKit lsp.
  NSDictionary<NSString *, id> *options = @ {
    // This is suitable for texures that are write-only to the CPU.
MTKTextureLoaderOptionTextureCPUCacheMode:
    [[NSNumber alloc] initWithUnsignedInt:MTLCPUCacheModeWriteCombined],
MTKTextureLoaderOptionOrigin:
    MTKTextureLoaderOriginBottomLeft,
  };
  NSError *error;
  id<MTLTexture> texture = [_loader
                            newTextureWithContentsOfURL:[NSURL fileURLWithPath:path]
                            options:options
                            error:&error
                           ];
  if (!texture) {
    NSLog(@"Error loading texture '%@': %@", path, error);
  }
  return texture;
}

@end
