//
//  DSSnapshot.m
//  DeviceSeekerSnapshot
//
//  Created by Micah Holden on 12/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DSSnapshot.h"

@interface DSSnapshot()
-(void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection;
@end

@implementation DSSnapshot

/*
 Constructor for the DSSnapshot class.
 Initializes variables.
*/
-(id)init
{
    self = [super init];
    mCaptureSession = nil;
    mCaptureDeviceInput = nil;
    mCaptureDecompressedVideoOutput = nil;
    mCurrentImageBuffer = nil;
    return self;
}

/* Clean up memory to avoid memory leaks */
-(void)dealloc
{
    if(mCaptureSession) [mCaptureSession release];
    if(mCaptureDeviceInput) [mCaptureDeviceInput release];
    if(mCaptureDecompressedVideoOutput) [mCaptureDecompressedVideoOutput release];
    CVBufferRelease(mCurrentImageBuffer);
    [super dealloc];
}

/*
 videoDevices - Gets the video devices that are connected to the computer
 returns: an array of all devices connected to the computer
*/
+(NSArray*)videoDevices
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:3];
    [results addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]];
    [results addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
    return results;
}

/*
 saveImage:toPath: - Saves an image to the specified path.
 params: image, the image to be saved, path, the path where the image will be saved
 returns: true if the save was successful, false otherwise
*/
+(BOOL)saveImage:(NSImage *)image toPath:(NSString *)path
{
    NSString *ext = [path pathExtension];
    NSData *photoData = [DSSnapshot dataFromImage:image asType:ext];
    return [photoData writeToFile:path atomically:NO];
}

/*
 dataFromImage:asType: - Converts an image into data that can then be saved to an image file.
 params: image, the image to be converted, type, the type of picture to save as
 returns: data that can be saved to a file
*/
+(NSData*)dataFromImage:(NSImage *)image asType:(NSString *)type
{
    NSData *tiffData = [image TIFFRepresentation];
    NSBitmapImageFileType imageType = NSJPEGFileType;
    NSDictionary *imageProps = nil;
    
    // Check what type to save as
    // TIFF - Can save immediately.
    if([@"tif" rangeOfString:type options:NSCaseInsensitiveSearch].location != NSNotFound ||
       [@"tiff" rangeOfString:type options:NSCaseInsensitiveSearch].location != NSNotFound)
        return tiffData;
    // JPEG
    else if([@"jpg" rangeOfString:type options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [@"jpeg" rangeOfString:type options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        imageType = NSJPEGFileType;
        imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
    }
    // PNG
    else if([@"png" rangeOfString:type options:NSCaseInsensitiveSearch].location != NSNotFound)
        imageType = NSPNGFileType;
    // BMP
    else if([@"bmp" rangeOfString:type options:NSCaseInsensitiveSearch].location != NSNotFound)
        imageType = NSBMPFileType;
    // GIF
    else if([@"gif" rangeOfString:type options:NSCaseInsensitiveSearch].location != NSNotFound)
        imageType = NSGIFFileType;
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:tiffData];
    NSData *photoData = [imageRep representationUsingType:imageType properties:imageProps];
    return photoData;
}

/*
 saveImageFromDevice:toFile: - Saves an image from the connected device to the specified path
 params: device, the device to capture the image from, path, the path to save the image to
 returns true if successful, false otherwise
*/
+(BOOL)saveImageFromDevice:(QTCaptureDevice *)device toFile:(NSString *)path
{
    DSSnapshot *snap;
    NSImage *image = nil;
    snap = [[DSSnapshot alloc]init];
    if([snap startSession:device])
        image = [snap snapshot];
    [snap release];
    return image == nil ? NO : [DSSnapshot saveImage:image toPath:path];
}

/*
 Takes a snapshot of the person using the computer
 returns: an image if successful, nil otherwise
*/
-(NSImage*)snapshot
{
    CVImageBufferRef frame = nil;
    while(frame == nil)
    {
        @synchronized(self)
        {
            frame = mCurrentImageBuffer;
            CVBufferRetain(frame);
        }
        if(frame == nil)
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:frame]];
    NSImage *image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
    [image addRepresentation:imageRep];
    return image;
}

/*
 startSession - Starts a capture session on the given device. 
 params: device, the device to start the capture on
 returns: true if successful, false otherwise
*/
-(BOOL)startSession:(QTCaptureDevice *)device
{
    if(device == nil)
        return NO;
    NSError *error = nil;
    if([device isEqual:[mCaptureDeviceInput device]] && mCaptureSession != nil && [mCaptureSession isRunning])
        return YES;
    else if(mCaptureSession != nil)
        [self stopSession];
    
    // Create capture session
    mCaptureSession = [[QTCaptureSession alloc] init];
    if(![device open:&error])
    {
        NSLog(@"Could not create capture session.");
        [mCaptureSession release];
        mCaptureSession = nil;
        return NO;
    }
    
    // Create input from device
    mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
    if(![mCaptureSession addInput:mCaptureDeviceInput error:&error])
    {
        NSLog(@"Could not convert device to input device.");
        [mCaptureSession release];
        [mCaptureDeviceInput release];
        mCaptureSession = nil;
        mCaptureDeviceInput = nil;
        return NO;
    }
    
    // Decompressed video output
    mCaptureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
    [mCaptureDecompressedVideoOutput setDelegate:self];
    if(![mCaptureSession addOutput:mCaptureDecompressedVideoOutput error:&error])
    {
        NSLog(@"Could not create decompressed output.");
        [mCaptureSession release];
        [mCaptureDeviceInput release];
        [mCaptureDecompressedVideoOutput release];
        mCaptureSession = nil;
        mCaptureDeviceInput = nil;
        mCaptureDecompressedVideoOutput = nil;
        return NO;
    }
    
    // Clear old image
    @synchronized(self)
    {
        if(mCurrentImageBuffer != nil)
        {
            CVBufferRelease(mCurrentImageBuffer);
            mCurrentImageBuffer = nil;
        }
    }
    [mCaptureSession startRunning];
    return YES;
}

/*
 stopSession - Stops the currently running capture session
*/
-(void)stopSession
{
    while (mCaptureSession != nil)
    {
        [mCaptureSession stopRunning];
        if([mCaptureSession isRunning])
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        else
        {
            if(mCaptureSession) [mCaptureSession release];
            if(mCaptureDeviceInput) [mCaptureDeviceInput release];
            if(mCaptureDecompressedVideoOutput) [mCaptureDecompressedVideoOutput release];
            mCaptureSession = nil;
            mCaptureDeviceInput = nil;
            mCaptureDecompressedVideoOutput = nil;
        }
    }
}

/*
 This delegate method is called whenever the QTCaptureDecompressedVideoOutput receives a frame
*/
-(void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
    if(videoFrame == nil)
        return;
    CVImageBufferRef imageToRelease;
    CVBufferRetain(videoFrame);
    @synchronized(self)
    {
        imageToRelease = mCurrentImageBuffer;
        mCurrentImageBuffer = videoFrame;
    }
    CVBufferRelease(imageToRelease);
}
@end

int process(int argc, const char *argv[]);

int main(int argc, const char * argv[])
{
    NSApplicationLoad();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    int result = process(argc,argv);
    [pool drain];
    return result;
}

/*
 process - Retrieves the user id, device id, and report id from the arguments and executes the program
 returns: 0 if successful, 1 if there are not 3 arguments passed in, 2 if there are no devices available, 3 otherwise
*/
int process(int argc, const char *argv[])
{
    NSString *filename = nil;
    NSArray *deviceList = [DSSnapshot videoDevices];
    NSArray *appSupport = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSLocalDomainMask, YES);
    BOOL success = NO;
    if(argc != 3)
    {
        NSLog(@"Not enough arguments.");
        return 1;
    }
    if([appSupport count])
    {
        filename = [[appSupport objectAtIndex:0] stringByAppendingPathComponent:@"DeviceSeeker"];
        filename = [filename stringByAppendingPathComponent:@"pics"];
        filename = [filename stringByAppendingPathComponent:[NSString stringWithFormat:@"%s_%s_snap.jpg",argv[1],argv[2]]];
    }
    if([deviceList count])
    {
        for(QTCaptureDevice *device in deviceList)
        {
            if([DSSnapshot saveImageFromDevice:device toFile:filename])
            {
                success = YES;
                break;
            }
        }
    }
    else
        return 2;
    return success ? 0:3;
}
