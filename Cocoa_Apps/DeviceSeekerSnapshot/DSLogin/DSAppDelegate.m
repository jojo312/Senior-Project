//
//  DSAppDelegate.m
//  DSLogin
//
//  Checks the given email and password for validation to be used in other scripts
//
//  Created by Micah Holden
//

#import "DSAppDelegate.h"

@implementation DSAppDelegate

@synthesize window;
@synthesize email;
@synthesize password;
@synthesize alert;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *appSupport = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSLocalDomainMask, YES);
    filePath = [[appSupport objectAtIndex:0] stringByAppendingPathComponent:@"DeviceSeeker"];
    if(![fileManager fileExistsAtPath:filePath])
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    filePath = [filePath stringByAppendingPathComponent:@"user.plist"];
}

/*
 submit - Checks if the email and password are valid
*/
-(IBAction)submit:(id)sender
{
    emailString = [email stringValue];
    passwordString = [password stringValue];
    if(emailString.length > 0 && passwordString.length > 0)
    {
        // Check if email and password are valid
        NSString *post = [NSString stringWithFormat:@"&email=%@&password=%@",emailString,passwordString];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
        NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
        [request setURL:[NSURL URLWithString:@"http://people.cis.ksu.edu/~mjholden/DMS/checkuser.php"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Current-Type"];
        [request setHTTPBody:postData];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if(conn)
            receivedData = [[NSMutableData data] retain];
        else
        {
            [alert setStringValue:@"Connection failed"];
            [alert setHidden:NO];
        }
    }
    else
    {
        [alert setHidden:NO];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [alert setStringValue:@"Connection failed"];
    [alert setHidden:NO];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *result = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    // Validate email and password
    if([result isEqualToString:@"true"])
    {
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:emailString,passwordString, nil] forKeys:[NSArray arrayWithObjects:@"email",@"pw", nil]];
        [dict writeToFile:filePath atomically:NO];
        [result release];
        // Close window and quit
        [window close];
        [NSApp terminate:nil];
    }
    else
    {
        [alert setStringValue:@"Email or password invalid"];
        [alert setHidden:NO];
    }
}

@end
