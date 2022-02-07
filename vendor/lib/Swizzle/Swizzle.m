// Swizzle.m
// Lib Swizzle
// Implementation based on https://defagos.github.io/yet_another_article_about_method_swizzling/
// and https://github.com/ReactiveCocoa/ReactiveCocoa/blob/legacy-objc/ReactiveCocoaFramework/ReactiveCocoa/NSObject%2BRACDeallocating.m

#import "Swizzle.h"

#import <objc/message.h>
#import <objc/runtime.h>

IMP class_swizzleSelector(Class clazz, SEL selector, IMP newImplementation)
{
    // If the method does not exist for this class, do nothing.
    Method method = class_getInstanceMethod(clazz, selector);
    if (!method) {
        // Cannot swizzle methods which are not implemented by the class or one of its parents
        return NULL;
    }

    // Make sure the class implements the method. If this is not the case, inject an implementation, only calling 'super'
    const char *types = method_getTypeEncoding(method);

#if !defined(__arm64__)
    NSUInteger returnSize = 0;
    NSGetSizeAndAlignment(types, &returnSize, NULL);

    // Large structs on 32-bit architectures
    if (sizeof(void *) == 4 && types[0] == _C_STRUCT_B && returnSize != 1 && returnSize != 2 && returnSize != 4 && returnSize != 8) {
        class_addMethod(clazz, selector, imp_implementationWithBlock(^(__unsafe_unretained id self, va_list argp) {
            struct objc_super super = {
                .receiver = self,
                .super_class = class_getSuperclass(clazz)
            };

            // Sufficiently large struct
            typedef struct LargeStruct_ {
                char dummy[16];
            } LargeStruct;

            // Cast the call to objc_msgSendSuper_stret appropriately
            LargeStruct (*objc_msgSendSuper_stret_typed)(struct objc_super *, SEL, va_list) = (void *)&objc_msgSendSuper_stret;
            return objc_msgSendSuper_stret_typed(&super, selector, argp);
        }), types);
    }
    // All other cases
    else {
#endif
        class_addMethod(clazz, selector, imp_implementationWithBlock(^(__unsafe_unretained id self, va_list argp) {
            struct objc_super super = {
                .receiver = self,
                .super_class = class_getSuperclass(clazz)
            };

            // Cast the call to objc_msgSendSuper appropriately
            id (*objc_msgSendSuper_typed)(struct objc_super *, SEL, va_list) = (void *)&objc_msgSendSuper;
            return objc_msgSendSuper_typed(&super, selector, argp);
        }), types);
#if !defined(__arm64__)
    }
#endif

    // Swizzling
    return class_replaceMethod(clazz, selector, newImplementation, types);
}

static NSMutableSet *swizzledClasses()
{
	static dispatch_once_t onceToken;
	static NSMutableSet *swizzledClasses = nil;
	dispatch_once(&onceToken, ^{
		swizzledClasses = [[NSMutableSet alloc] init];
	});
	return swizzledClasses;
}

static void swizzleDeallocIfNeeded(Class classToSwizzle)
{
    // CUSTOM IMPLEMENTATION
// #define ENABLE_CUSTOM
#ifdef ENABLE_CUSTOM
	@synchronized (swizzledClasses()) {
		NSString *className = NSStringFromClass(classToSwizzle);
		if ([swizzledClasses() containsObject:className]) {
		    return;
		}
		SEL selector = sel_registerName("dealloc");
		Method originalMethod = class_getInstanceMethod(classToSwizzle, selector);
		void (*originalImplementation)(__unsafe_unretained id, SEL) =
		    (__typeof__(originalImplementation))method_getImplementation(originalMethod);
		id newImplementationBlock = ^(__unsafe_unretained id obj) {
            //RACCompoundDisposable *compoundDisposable = objc_getAssociatedObject(obj, RACObjectCompoundDisposable);
            //[compoundDisposable dispose];
            printf("Custom -dealloc\n");
            ((void (*)(__unsafe_unretained id, SEL))originalImplementation)(obj, selector);
        };
		IMP newImplementation = imp_implementationWithBlock(newImplementationBlock);
        class_swizzleSelector(classToSwizzle, selector, newImplementation);
        [swizzledClasses() addObject:className];
	}
#endif

    // v3.0 IMPLEMENTATION
#define ENABLE_V3
#ifdef ENABLE_V3
	@synchronized (swizzledClasses()) {
		NSString *className = NSStringFromClass(classToSwizzle);
		if ([swizzledClasses() containsObject:className]) return;

		SEL deallocSelector = sel_registerName("dealloc");

		__block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;

		id newDealloc = ^(__unsafe_unretained id self) {
			//RACCompoundDisposable *compoundDisposable = objc_getAssociatedObject(self, RACObjectCompoundDisposable);
			//[compoundDisposable dispose];
            printf("Custom -dealloc\n");

			if (originalDealloc == NULL) {
				struct objc_super superInfo = {
					.receiver = self,
					.super_class = class_getSuperclass(classToSwizzle)
				};

				void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
				msgSend(&superInfo, deallocSelector);
			} else {
				originalDealloc(self, deallocSelector);
			}
		};

		IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);

		if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {
			// The class already contains a method implementation.
			Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);

			// We need to store original implementation before setting new implementation
			// in case method is called at the time of setting.
			originalDealloc = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);

			// We need to store original implementation again, in case it just changed.
			originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
		}

		[swizzledClasses() addObject:className];
	}
#endif
}

@implementation Swizzler

+ (void)swizzleDeallocForClass:(Class)clazz
{
    swizzleDeallocIfNeeded(clazz);
}

+ (void)swizzleDeallocForObject:(id)object
{
    swizzleDeallocIfNeeded([object class]);
}

@end
