#import <Metal/Metal.h>

@interface TextureLoader : NSObject

- (TextureLoader *)initWithDevice:(id<MTLDevice>)device;

- (id<MTLTexture>)getTextureWithPath:(NSString *)path;

@end
