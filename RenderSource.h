#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <stdint.h>

#import "Vertex.h"

@interface RenderSource : NSObject

@property NSData *vertices;

@property NSData *vertexIndices;

@property NSUInteger vertexIndexCount;

@property MTLClearColor clearColor;

- (void)tick;

@end
