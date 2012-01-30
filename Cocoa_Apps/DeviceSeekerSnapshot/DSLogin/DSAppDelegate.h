//
//  DSAppDelegate.h
//  DSLogin
//
//  Created by Micah Holden on 12/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DSAppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSWindow *window;
    IBOutlet NSTextField *email, *alert;
    IBOutlet NSSecureTextField *password;
    NSMutableData *receivedData;
    NSString *filePath,*emailString,*passwordString;
}
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *email;
@property (assign) IBOutlet NSSecureTextField *password;
@property (assign) IBOutlet NSTextField *alert;

-(IBAction)submit:(id)sender;
@end
