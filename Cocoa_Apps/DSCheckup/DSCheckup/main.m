//
//  main.m
//  DSCheckup
//
//  Created by Micah Holden on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSCheckup.h"

int main (int argc, const char * argv[])
{

    @autoreleasepool
    {
        [[DSCheckup alloc] checkup];
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}

