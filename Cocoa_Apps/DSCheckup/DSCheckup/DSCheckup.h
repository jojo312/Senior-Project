//
//  DSCheckup.h
//  DSCheckup
//
//  Created by Micah Holden on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <QTKit/QTKit.h>
#import "DSSnapshot.h"

@interface DSCheckup : NSObject
{
    NSMutableData *sendInfoData,*createDevData, *checkLostData;
    NSString *filePath, *fileDirectory, *email, *pw, *devid, *repid;
    NSMutableDictionary *userInfo;
    NSURLConnection *sendInfoConn,*createDevConn, *checkLostConn;
    BOOL deviceCreated;
}

-(void)checkup;
-(void)sendInfo;
-(NSString*)getLocation;
-(NSString*)takeScreenshot;
-(void)uploadPics;

@end
