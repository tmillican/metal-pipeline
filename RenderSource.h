#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface RenderSource : NSObject

@property NSString *shaderPath;

@property NSData *vertices;

@property NSData *vertexIndices;

@property MTLClearColor clearColor;

@property NSArray *texturePaths;

@property NSMutableArray *uniforms;

- (void)tick;

@end
