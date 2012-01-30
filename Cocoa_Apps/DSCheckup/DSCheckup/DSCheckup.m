//
//  DSCheckup.m
//  DSCheckup
//
//  Created by Micah Holden on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DSCheckup.h"

@implementation DSCheckup

-(void)checkup
{
    // Get email, password, and device id from stored dictionary
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *appSupport = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSLocalDomainMask, YES);
    fileDirectory = [[appSupport objectAtIndex:0] stringByAppendingPathComponent:@"DeviceSeeker"];
    if([fileManager fileExistsAtPath:fileDirectory])
    {
        filePath = [fileDirectory stringByAppendingPathComponent:@"user.plist"];
        if([fileManager fileExistsAtPath:filePath])
            userInfo = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
        else
        {
            // If file doesn't exist, then the user needs to sign in.
            [[NSWorkspace sharedWorkspace] launchApplication:@"DSLogin"];
            exit(0);
        }
    }
    else
    {
        [fileManager createDirectoryAtPath:fileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        // File doesn't exist, so the user needs to sign in.
        [[NSWorkspace sharedWorkspace] launchApplication:@"DSLogin"];
        exit(0);
    }
    
    if(!userInfo)
    {
        // No info found so exit
        [[NSWorkspace sharedWorkspace] launchApplication:@"DSLogin"];
        exit(0);
    }
    
    // Check values in user info
    email = [userInfo objectForKey:@"email"];
    pw = [userInfo objectForKey:@"pw"];
    devid = [userInfo objectForKey:@"devid"];
    if(!email || !pw)
    {
        [[NSWorkspace sharedWorkspace] launchApplication:@"DSLogin"];
        exit(0);
    }
    else if(email && pw && (!devid || [devid length] == 0))
    {
        NSString *devname = [[NSHost currentHost] localizedName];
        NSString *post = [NSString stringWithFormat:@"&email=%@&password=%@&devname=%@",email,pw,devname];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
        NSMutableURLRequest *request = [[[NSMutableURLRequest alloc]init] autorelease];
        [request setURL:[NSURL URLWithString:@"http://people.cis.ksu.edu/~mjholden/DMS/createdev.php"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Current-Type"];
        [request setHTTPBody:postData];
        createDevConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if(createDevConn)
            createDevData = [[NSMutableData data] retain];
        else
        {
            NSLog(@"Connection could not be made");
            exit(0);
        }
    }
    else
    {
        NSString *post = [NSString stringWithFormat:@"&email=%@&password=%@&devid=%@",email,pw,devid];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
        NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
        [request setURL:[NSURL URLWithString:@"http://people.cis.ksu.edu/~mjholden/DMS/checklost.php"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Current-Type"];
        [request setHTTPBody:postData];
        checkLostConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if(checkLostConn)
            checkLostData = [[NSMutableData data] retain];
        else
        {
            NSLog(@"Connection could not be made");
            exit(0);
        }
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if([connection isEqualTo:createDevConn])
        [createDevData appendData:data];
    else if([connection isEqualTo:checkLostConn])
        [checkLostData appendData:data];
    else if([sendInfoConn isEqualTo:sendInfoData])
        [sendInfoData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if([connection isEqualTo:createDevConn])
        [createDevData setLength:0];
    else if([connection isEqualTo:checkLostConn])
        [checkLostData setLength:0];
    else if([connection isEqualTo:sendInfoConn])
        [sendInfoData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if(createDevConn) [createDevConn release];
    if(createDevData) [createDevData release];
    if(checkLostConn) [checkLostConn release];
    if(checkLostData) [checkLostData release];
    if(sendInfoConn) [sendInfoConn release];
    if(sendInfoData) [sendInfoData release];
    NSLog(@"Connection failed! Error - %@ %@",[error localizedDescription],[[error userInfo] objectForKey:NSURLErrorFailingURLErrorKey]);
    exit(0);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if([connection isEqualTo:createDevConn])
    {
        NSString *result = [[NSString alloc] initWithData:createDevData encoding:NSUTF8StringEncoding];
        NSLog(@"devid = %@",result);
        if([result intValue] > 0)
        {
            [userInfo setObject:result forKey:@"devid"];
            [userInfo writeToFile:filePath atomically:YES];
        }
        [createDevConn release];
        [createDevData release];
        exit(0);
    }
    else if([connection isEqualTo:checkLostConn])
    {
        repid = [[NSString alloc] initWithData:checkLostData encoding:NSUTF8StringEncoding];
        NSLog(@"repid = %@",repid);
        [checkLostConn release];
        [checkLostData release];
        if([repid intValue] > 0)
            [self sendInfo];
        else
            exit(0);
    }
    else if([connection isEqualTo:sendInfoConn])
    {
        NSString *result = [[NSString alloc]initWithData:sendInfoData encoding:NSUTF8StringEncoding];
        NSLog(@"result = %@",result);
        [sendInfoConn release];
        [sendInfoData release];
        exit(0);
    }
}

-(void)sendInfo
{
    // Get Location
    NSString *loc = [self getLocation];
    // Take Screenshot
    NSString *screenpath = [NSString stringWithFormat:@"/~mjholden/DMS/pics/%@_%@_screen.jpg",devid,repid];
    [self takeScreenshot];
    // Take Snapshot
    NSArray *deviceList = [DSSnapshot videoDevices];
    NSString *snappath = [NSString stringWithFormat:@"/~mjholden/DMS/pics/%@_%@_snap.jpg",devid,repid];
    if([deviceList count] > 0)
    {
        NSString *snapp = [fileDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@_snap.jpg",devid,repid]];
        for(QTCaptureDevice *device in deviceList)
        {
            if([DSSnapshot saveImageFromDevice:device toFile:snapp])
                break;
        }
    }
    // Get Internal IP
    NSArray *addresses = [[NSHost currentHost] addresses];
    NSString *intIP = @"";
    for(NSString *address in addresses)
    {
        if(![address hasPrefix:@"127"] && [[address componentsSeparatedByString:@"."] count] == 4)
        {
            intIP = address;
            break;
        }
    }
    // Get External IP
    NSString *extIP = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www.whatismyip.org"] encoding:NSASCIIStringEncoding error:nil];
    // Upload Screenshot and Snapshot
    //[self uploadPics];
    NSString *post = [NSString stringWithFormat:@"&email=%@&password=%@&repid=%@&snappath=%@&screenpath=%@&location=%@&intip=%@&extip=%@",email,pw,repid,snappath,screenpath,loc,intIP,extIP];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setURL:[NSURL URLWithString:@"http://people.cis.ksu.edu/~mjholden/DMS/updatereport.php"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Current-Type"];
    [request setHTTPBody:postData];
    sendInfoConn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(sendInfoConn)
        sendInfoData = [[NSMutableData data] retain];
    else
    {
        NSLog(@"Connection could not be made");
        exit(0);
    }
}

-(NSString*)getLocation
{
    NSString *path = [fileDirectory stringByAppendingPathComponent:@"scripts"];
    path = [path stringByAppendingPathComponent:@"DSLocation"];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[NSArray arrayWithObjects:@"-c",[NSString stringWithFormat:@"\"%@\"",path], nil]];
    NSPipe *readPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [readPipe fileHandleForReading];
    [task setStandardOutput:readPipe];
    [task launch];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSData *readData;
    while((readData = [readHandle availableData]) && [readData length])
        [data appendData:readData];
    NSString *result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    [task release];
    [data release];
    [result autorelease];
    return result;
}

-(NSString*)takeScreenshot
{
    NSString *screenpath = [fileDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@_screen.jpg",devid,repid]];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[NSArray arrayWithObjects:@"-c",[NSString stringWithFormat:@"screencapture -Sx \"%@\"",screenpath], nil]];
    NSPipe *readPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [readPipe fileHandleForReading];
    [task setStandardOutput:readPipe];
    [task launch];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSData *readData;
    while((readData = [readHandle availableData]) && [readData length])
        [data appendData:readData];
    NSString *result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    [task release];
    [data release];
    [result autorelease];
    return result;
}

/*
 uploadPics - Uploads the snapshot and screenshot to the website
*/
-(void)uploadPics
{
    NSString *dir = [fileDirectory stringByAppendingPathComponent:@"pics"];
    NSString *screenpath = [NSString stringWithFormat:@"%@_%@_screen.jpg",devid,repid];
    NSString *snappath = [NSString stringWithFormat:@"%@_%@_snap.jpg",devid,repid];
    NSData *screenshot = [NSData dataWithContentsOfFile:[dir stringByAppendingPathComponent:screenpath]];
    NSData *snapshot = [NSData dataWithContentsOfFile:[dir stringByAppendingPathComponent:snappath]];
    // Upload screenshot
    NSMutableURLRequest *screenrequest = [[[NSMutableURLRequest alloc]init]autorelease];
    [screenrequest setURL:[NSURL URLWithString:@"http://people.cis.ksu.edu/~mjholden/DMS/upload.php"]];
    [screenrequest setHTTPMethod:@"POST"];
    NSString *boundary = @"----------Fslenmgswbcxpqiewak";
    [screenrequest addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary] forHTTPHeaderField:@"Content-Type"];
    NSMutableData *screenbody = [NSMutableData data];
    [screenbody appendData:[[NSString stringWithFormat:@"rn--%@rn",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [screenbody appendData:[[NSString stringWithFormat:@"Content-Disposition:form-data; name=\"file\";filename=\"%@_%@_screen.jpg\"rn",devid,repid] dataUsingEncoding:NSUTF8StringEncoding]];
    [screenbody appendData:[@"Content-Type:application/octet-streamrnrn" dataUsingEncoding:NSUTF8StringEncoding]];
    [screenbody appendData:screenshot];
    [screenbody appendData:[[NSString stringWithFormat:@"rn--%@--rn",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [screenrequest setHTTPBody:screenbody];
    // Upload snapshot
    NSMutableURLRequest *snaprequest = [[[NSMutableURLRequest alloc]init]autorelease];
    [snaprequest setURL:[NSURL URLWithString:@"http://people.cis.ksu.edu/~mjholden/DMS/upload.php"]];
    [snaprequest setHTTPMethod:@"POST"];
    [snaprequest addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary] forHTTPHeaderField:@"Content-Type"];
    NSMutableData *snapbody = [NSMutableData data];
    [snapbody appendData:[[NSString stringWithFormat:@"rn--%@rn",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [snapbody appendData:[[NSString stringWithFormat:@"Content-Disposition:form-data; name=\"file\";filename=\"%@_%@_snap.jpg\"rn",devid,repid] dataUsingEncoding:NSUTF8StringEncoding]];
    [snapbody appendData:[@"Content-Type:application/octet-streamrnrn" dataUsingEncoding:NSUTF8StringEncoding]];
    [snapbody appendData:snapshot];
    [snapbody appendData:[[NSString stringWithFormat:@"rn--%@--rn",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [snaprequest setHTTPBody:snapbody];
    // Get results
    [NSURLConnection sendSynchronousRequest:screenrequest returningResponse:nil error:nil];
    [NSURLConnection sendSynchronousRequest:snaprequest returningResponse:nil error:nil];
}

@end
