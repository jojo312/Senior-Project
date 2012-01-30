//
//  DSSnapshot.h
//  DSCheckup
//
//  Created by Micah Holden on 12/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>

@interface DSSnapshot : NSObject
{
    QTCaptureSession *mCaptureSession;
    QTCaptureDeviceInput *mCaptureDeviceInput;
    QTCaptureDecompressedVideoOutput *mCaptureDecompressedVideoOutput;
    CVImageBufferRef mCurrentImageBuffer;
}

+(NSArray*)videoDevices;
+(BOOL)saveImage:(NSImage*)image toPath:(NSString*)path;
+(NSData*)dataFromImage:(NSImage*)image asType:(NSString*)type;
+(BOOL)saveImageFromDevice:(QTCaptureDevice*)device toFile:(NSString*)path;
-(id)init;
-(void)dealloc;
-(BOOL)startSession:(QTCaptureDevice*)device;
-(NSImage*)snapshot;
-(void)stopSession;

@end
