//
//  NSStoryboard+Swizzling.m
//  SwinjectStoryboard
//
//  Created by Mark DiFranco on 2017-03-31.
//  Copyright © 2017 Swinject Contributors. All rights reserved.
//

#import "NSStoryboard+Swizzling.h"
#import <objc/runtime.h>

#if __has_include(<SwinjectStoryboard/SwinjectStoryboard-Swift.h>)
    #import <SwinjectStoryboard/SwinjectStoryboard-Swift.h>
#elif __has_include("SwinjectStoryboard-Swift.h")
    #import "SwinjectStoryboard-Swift.h"
#endif

#import <SwinjectStoryboard/SwinjectStoryboardProtocol.h>

@implementation NSStoryboard (Swizzling)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = object_getClass((id)self);

        SEL originalSelector = @selector(storyboardWithName:bundle:);
        SEL swizzledSelector = @selector(swinject_storyboardWithName:bundle:);

        Method originalMethod = class_getClassMethod(class, originalSelector);
        Method swizzledMethod = class_getClassMethod(class, swizzledSelector);

        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

+ (nonnull instancetype)swinject_storyboardWithName:(NSStoryboardName)name bundle:(nullable NSBundle *)storyboardBundleOrNil {
    if (self == [NSStoryboard class]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

        // Instantiate SwinjectStoryboard if NSStoryboard is trying to be instantiated.
        if ([[SwinjectStoryboard class] performSelector:@selector(isCreatingStoryboardReference)]) {
            return [[SwinjectStoryboard class] performSelector:@selector(createReferencedWithName:bundle:)
                                                    withObject: name
                                                    withObject: storyboardBundleOrNil];
        } else {
            return [SwinjectStoryboard createWithName:name bundle:storyboardBundleOrNil];
        }
#pragma clang diagnostic pop
    } else {
        return [self swinject_storyboardWithName:name bundle:storyboardBundleOrNil];
    }
}

@end
