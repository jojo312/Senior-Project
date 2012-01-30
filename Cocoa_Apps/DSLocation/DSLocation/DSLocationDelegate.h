//
//  DSLocationDelegate.h
//  DSLocation
//
//  Created by Micah Holden on 12/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>

@interface DSLocationDelegate : NSObject <NSApplicationDelegate, CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
}
-(void)currentLocation;

@end
