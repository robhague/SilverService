// ServiceProvider.m
//
// (c) Copyright 2004 Rob Hague
//
// This file is part of SilverService.
//
// SilverService is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// Foobar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Foobar; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#import "ServiceProvider.h"

@implementation ServiceProvider

- (IBAction)refresh:(id)sender
{
    NSUpdateDynamicServices();
}

/* Funciton to pop up a result window */
void newResultWindow(NSString *name,NSString *outputString,int w,int h)
{
    NSWindow *win = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,w,h)
                                                styleMask: (NSTitledWindowMask |
                                                            NSClosableWindowMask |
                                                            NSResizableWindowMask)
                                                  backing: NSBackingStoreBuffered
                                                    defer: NO];
    [win setAutodisplay: YES];
    [win setTitle: [NSString stringWithFormat: @"SilverService Results - %@", name]];
    [win center];
    [win setOneShot: YES];
    
    NSTextView *tv = [[NSTextView alloc] initWithFrame: NSMakeRect(0,0,10,10)];
    [tv setHorizontallyResizable: YES];
    [tv setVerticallyResizable: YES];
    [tv insertText: outputString];
    [tv setDrawsBackground: YES];

    NSScrollView *sv = [[NSScrollView alloc] init];
    [sv setHasHorizontalScroller: YES];
    [sv setHasVerticalScroller: YES];
    [sv setDocumentView: tv];
    [win setContentView: sv];
    
    [win orderFront: win];
}

/* A big monolithic method that basically does everything. Modularity - I've heard of it.*/
- (void)shellService:(NSPasteboard *)pboard
            userData:(NSString *)userData error:(NSString **)error
{
    /* Variables that are used throughout */
    NSString *command; /* The command string to pass to the shell */
    NSMutableDictionary *atts; /* The attributes of the invoked service */
    NSString *inputString = nil; /* Input from the calling application */
    NSString *outputString = nil; /* Output from the shell */

    /* Scan the user data */
    atts = [userData propertyList];
    command = [atts objectForKey: @"command"];
    
    /* Get the input from the calling application */
    if ([[pboard types] containsObject:NSStringPboardType])
        inputString = [pboard stringForType:NSStringPboardType];
    
    /* Set up the task */
    NSTask *shellTask = [[NSTask alloc] init];
    [shellTask setLaunchPath: @"/bin/bash"];
    if ([[atts objectForKey: @"in"] isEqualToString: @"string"])
        command = [NSString stringWithFormat: command, inputString];
    [shellTask setArguments: [NSArray arrayWithObjects: @"-c", command, nil]];

    /* Connect inputs and output */
    NSPipe *inPipe = [NSPipe pipe], *outPipe = [NSPipe pipe];
    if ([[atts objectForKey: @"in"] isEqualToString: @"stdin"])
    {
        [shellTask setStandardInput: inPipe];
    }
    if (![[atts objectForKey: @"out"] isEqualToString: @"none"])
    {
        [shellTask setStandardOutput: outPipe];
    }

    /* Run the task, piping in the input if necessary */
    [shellTask launch];
    if ([[atts objectForKey: @"in"] isEqualToString: @"stdin"])
    {
        NSFileHandle *fh = [inPipe fileHandleForWriting];
        [fh writeData: [inputString dataUsingEncoding: NSUTF8StringEncoding]];
        [fh closeFile];
    }

    /* Retreive the output if neccesary */
    if (![[atts objectForKey: @"out"] isEqualToString: @"none"])
        outputString = [[NSString alloc] initWithData: [[outPipe fileHandleForReading] readDataToEndOfFile]
                                             encoding: NSUTF8StringEncoding];

    /* Send any output back to the caller */
    if ([[atts objectForKey: @"out"] isEqualToString: @"service"])
    {
        [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pboard setString:outputString forType:NSStringPboardType];
    }

    /* Pop up the output in a panel if needed */
    if ([[atts objectForKey: @"out"] isEqualToString: @"panel"])
        newResultWindow([atts objectForKey: @"name"], outputString,
                        [atts objectForKey: @"panelw"]?[[atts objectForKey: @"panelw"] intValue]:300,
                        [atts objectForKey: @"panelh"]?[[atts objectForKey: @"panelh"] intValue]:200);

    /* And relax */
    return;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSApp setServicesProvider: self];
}
@end
