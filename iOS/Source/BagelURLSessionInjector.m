//
// Copyright (c) 2018 Bagel (https://github.com/yagiz/Bagel)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BagelURLSessionInjector.h"
#import "Bagel.h"
#include <objc/runtime.h>

@implementation BagelURLSessionInjector

- (instancetype)initWithDelegate:(id<BagelURLSessionInjectorDelegate>)delegate
{
    self = [super init];

    if (self) {
        self.delegate = delegate;
        [self inject];
    }

    return self;
}

/*
 dump:
 - (void)_didFinishWithError:(id)arg1;
 - (void)_didReceiveData:(id)arg1;
 - (void)_didReceiveResponse:(id)arg1 sniff:(bool)arg2; // ~> iOS 12
 - (void)_didReceiveResponse:(id)arg1 sniff:(bool)arg2 rewrite:(bool)arg3; // iOS 13
 
 https://github.com/JackRostron/iOS8-Runtime-Headers
 https://github.com/ksenks/iOS9-Runtime-Headers
 https://github.com/JaviSoto/iOS10-Runtime-Headers
 https://github.com/LeoNatan/Apple-Runtime-Headers
 */

#pragma mark NSURLSession Injection

- (void)inject
{
    static dispatch_once_t NSURLSessionInjectionOnce;

    dispatch_once(&NSURLSessionInjectionOnce, ^{

        [self _inject];

    });
}

- (void)_inject
{
    //iOS8          : __NSCFURLSessionConnection
    //iOS9,10,11    : __NSCFURLLocalSessionConnection

    Class sessionClass = NSClassFromString(@"__NSCFURLLocalSessionConnection");

    if (sessionClass == nil) {
        sessionClass = NSClassFromString(@"__NSCFURLSessionConnection");
    }

    if (sessionClass) {
        [self swizzleSessionDidReceiveData:sessionClass];
        [self swizzleSessionDidReceiveResponse:sessionClass];
        [self swizzleSessiondDidFinishWithError:sessionClass];
    }

    // Swizzle resume on ALL NSURLSessionTask subclasses.
    // The original approach only targeted __NSCFURLSessionTask, but modern
    // async/await APIs (e.g. URLSession.shared.data(from:)) may use different
    // internal task subclasses where resume is not inherited from that class.
    Class baseTaskClass = [NSURLSessionTask class];
    NSMutableSet *swizzledIMPs = [NSMutableSet new];

    unsigned int numOfClasses;
    Class *classes = objc_copyClassList(&numOfClasses);
    for (unsigned int i = 0; i < numOfClasses; i++) {
        Class cls = classes[i];

        // Walk superclass chain to check if cls is a subclass of NSURLSessionTask
        Class superclass = class_getSuperclass(cls);
        BOOL isSubclass = NO;
        while (superclass) {
            if (superclass == baseTaskClass) {
                isSubclass = YES;
                break;
            }
            superclass = class_getSuperclass(superclass);
        }

        if (!isSubclass) {
            continue;
        }

        // Avoid double-swizzling the same IMP (inherited implementations)
        SEL resumeSel = NSSelectorFromString(@"resume");
        Method m = class_getInstanceMethod(cls, resumeSel);
        if (m) {
            NSValue *impValue = [NSValue valueWithPointer:method_getImplementation(m)];
            if (![swizzledIMPs containsObject:impValue]) {
                [swizzledIMPs addObject:impValue];
                [self swizzleSessionTaskResume:cls];
            }
        }
    }
    free(classes);
}

- (void)swizzleSessionTaskResume:(Class) class
{
    SEL selector = NSSelectorFromString(@"resume");
    Method m = class_getInstanceMethod(class, selector);

    if (m && [class instancesRespondToSelector:selector]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(m);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessionTaskResume)(id) = ^void(id self) {

            [weakSelf.delegate urlSessionInjector:weakSelf didStart:self];

            originalIMPBlock(self, _cmd);
        };

        method_setImplementation(m, imp_implementationWithBlock(swizzledSessionTaskResume));
    }
}

    - (void)swizzleSessionDidReceiveResponse : (Class) class
{
    SEL selectorWithRewrite = NSSelectorFromString(@"_didReceiveResponse:sniff:rewrite:");
    Method mRewrite = class_getInstanceMethod(class, selectorWithRewrite);

    if (mRewrite && [class instancesRespondToSelector:selectorWithRewrite]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd, id arg1, BOOL sniff, BOOL rewrite);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(mRewrite);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessionDidReceiveResponse)(id, id, BOOL, BOOL) = ^void(id self, id arg1, BOOL sniff, BOOL rewrite) {

            [weakSelf.delegate urlSessionInjector:weakSelf didReceiveResponse:[self valueForKey:@"task"] response:arg1];

            originalIMPBlock(self, _cmd, arg1, sniff, rewrite);
        };

        method_setImplementation(mRewrite, imp_implementationWithBlock(swizzledSessionDidReceiveResponse));
        return;
    }

    SEL selector = NSSelectorFromString(@"_didReceiveResponse:sniff:");
    Method m = class_getInstanceMethod(class, selector);

    if (m && [class instancesRespondToSelector:selector]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd, id arg1, BOOL sniff);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(m);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessionDidReceiveResponse)(id, id, BOOL) = ^void(id self, id arg1, BOOL sniff) {

            [weakSelf.delegate urlSessionInjector:weakSelf didReceiveResponse:[self valueForKey:@"task"] response:arg1];

            originalIMPBlock(self, _cmd, arg1, sniff);
        };

        method_setImplementation(m, imp_implementationWithBlock(swizzledSessionDidReceiveResponse));
    }
}

    - (void)swizzleSessionDidReceiveData : (Class) class
{
    SEL selector = NSSelectorFromString(@"_didReceiveData:");
    Method m = class_getInstanceMethod(class, selector);

    if (m && [class instancesRespondToSelector:selector]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd, id arg1);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(m);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessionDidReceiveData)(id, id) = ^void(id self, id arg1) {

            [weakSelf.delegate urlSessionInjector:weakSelf didReceiveData:[self valueForKey:@"task"] data:[arg1 copy]];

            originalIMPBlock(self, _cmd, arg1);
        };

        method_setImplementation(m, imp_implementationWithBlock(swizzledSessionDidReceiveData));
    }
}

- (void)swizzleSessiondDidFinishWithError : (Class) class
{
    SEL selector = NSSelectorFromString(@"_didFinishWithError:");
    Method m = class_getInstanceMethod(class, selector);

    if (m && [class instancesRespondToSelector:selector]) {

        typedef void (*OriginalIMPBlockType)(id self, SEL _cmd, id arg1);
        OriginalIMPBlockType originalIMPBlock = (OriginalIMPBlockType)method_getImplementation(m);

        __weak BagelURLSessionInjector* weakSelf = self;

        void (^swizzledSessiondDidFinishWithError)(id, id) = ^void(id self, id arg1) {

            [weakSelf.delegate urlSessionInjector:weakSelf didFinishWithError:[self valueForKey:@"task"] error:arg1];

            originalIMPBlock(self, _cmd, arg1);
        };

        method_setImplementation(m, imp_implementationWithBlock(swizzledSessiondDidFinishWithError));
    }
}

@end
