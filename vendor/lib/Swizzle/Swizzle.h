// Swizzle.h
// Lib Swizzle

#import <Foundation/Foundation.h>

@interface Swizzler : NSObject

+ (void)swizzleDeallocForClass:(Class)clazz;
+ (void)swizzleDeallocForObject:(id)object;

@end
