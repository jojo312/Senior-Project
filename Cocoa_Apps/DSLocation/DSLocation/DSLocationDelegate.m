//
//  DSLocationDelegate.m
//  DSLocation
//
//  Created by Micah Holden on 12/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DSLocationDelegate.h"

@implementation DSLocationDelegate

-(void)currentLocation
{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    printf("ERROR: %s\n",[[error localizedDescription] UTF8String]);
    exit(1);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSString *loc = [[[newLocation.description substringToIndex:[newLocation.description rangeOfString:@">"].location] substringFromIndex:1] stringByReplacingOccurrencesOfString:@" " withString:@""];
    printf("%s\n",[loc UTF8String]);
    exit(0);
}

@end
