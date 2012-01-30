//
//  main.m
//  DSLocation
//
//  Created by Micah Holden on 12/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Cocoa/Cocoa.h>
#include <dispatch/dispatch.h>
#import "DSLocationDelegate.h"

int main (int argc, const char * argv[])
{

    @autoreleasepool
    {
        [[DSLocationDelegate alloc] currentLocation];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop run];
    }
    return 0;
}

