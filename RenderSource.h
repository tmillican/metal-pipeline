#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <stdint.h>

#import "Vertex.h"

@interface RenderSource : NSObject

@property NSData *vertices;

@property NSData *vertexIndices;

@property MTLClearColor clearColor;

@property NSArray *texturePaths;

@property NSMutableArray *uniformDescriptors;

- (void)tick;

@end
