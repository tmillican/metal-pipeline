#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <stdint.h>

#import "Vertex.h"

@interface RenderSource : NSObject

@property Vertex *vertices;

@property NSUInteger vertexCount;

@property uint32_t *vertexIndices;

@property NSUInteger vertexIndexCount;

@property MTLClearColor clearColor;

- (void)tick;

@end
