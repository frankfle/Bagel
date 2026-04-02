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

#if __has_include(<UIKit/UIKit.h>)
@import UIKit;
#endif
@import Foundation;
#if TARGET_OS_OSX
#include <sys/sysctl.h>
#endif
#import "BagelUtility.h"

@implementation BagelUtility

+ (NSString*)UUID
{
    return [[NSUUID UUID] UUIDString];
}

+ (NSString*)projectName
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
}

+ (NSString*)deviceId
{
    return [NSString stringWithFormat:@"%@-%@", [self deviceName], [self deviceDescription]];
}

+ (NSString*)deviceName
{
#if TARGET_OS_OSX
    return [[NSProcessInfo processInfo] hostName];
#else
    return [UIDevice currentDevice].name;
#endif
}

+ (NSString*)deviceDescription
{
#if TARGET_OS_OSX
    NSString* model = @"Mac";
    size_t size;
    sysctlbyname("hw.model", NULL, &size, NULL, 0);
    if (size > 0) {
        char *machine = malloc(size);
        sysctlbyname("hw.model", machine, &size, NULL, 0);
        model = [NSString stringWithUTF8String:machine];
        free(machine);
    }
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    return [NSString stringWithFormat:@"%@ macOS %ld.%ld.%ld",
            model, (long)version.majorVersion, (long)version.minorVersion, (long)version.patchVersion];
#else
    NSString* information = @"";
    information = [UIDevice currentDevice].model;
    information = [NSString stringWithFormat:@"%@ %@", information, [UIDevice currentDevice].systemName];
    information = [NSString stringWithFormat:@"%@ %@", information, [UIDevice currentDevice].systemVersion];
    return information;
#endif
}

@end


