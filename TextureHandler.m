#import <MetalKit/MetalKit.h>

#import "TextureHandler.h"
#import "Renderer.h"

// Handles the loading and binding of textures.
// Uses a very simple-minded caching texture loader with no storage limits.

@implementation TextureHandler {
  id<MTLDevice> _device;
  RenderSource *_source;
  MTKTextureLoader *_loader;
  NSMutableDictionary<NSString*, id<MTLTexture>> *_cache;
}

- (TextureHandler *)initWithDevice:(id<MTLDevice>)device source:(RenderSource *)source
{
  self = [super init];
  if (!self) return self;

  _device = device;
  _source = source;
  _loader = [[MTKTextureLoader alloc] initWithDevice:_device];
  _cache = [[NSMutableDictionary alloc] init];

  return self;
}

// Loads the textures specified by `RenderSource.texturePaths`, either from
// cache or disk and binds them to entries in the fragment shader's texture
// argument table.
- (void)handleWithCommandEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
{
  for (size_t i = 0; i < [Renderer getTextureSlotCount]; i++) {
    if (_source.texturePaths[i] == [NSNull null]) continue;
    id texture = [self getTextureWithPath:_source.texturePaths[i]];
    [commandEncoder setFragmentTexture:texture atIndex:i];
  }
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
  NSDictionary<NSString *, id> *options = @ {
    // This is suitable for texures that are write-only to the CPU.
MTKTextureLoaderOptionTextureCPUCacheMode:
    [[NSNumber alloc] initWithUnsignedInt:MTLCPUCacheModeWriteCombined],
    // Flip the coordinates of an image only as needed to make the origin
    // be the bottom left.
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
