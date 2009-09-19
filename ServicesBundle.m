// ServicesBundle.m
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

#import "ServicesBundle.h"

@implementation ServicesBundle

-(void)awakeFromNib
{
    plistPath = [@"~/Library/Services/SilverService.service/Contents/Info.plist"
        stringByExpandingTildeInPath];
    [plistPath retain];

    /* If this is the first time that this user has run SilverService, create it
        and display an explanatory message. */

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath: plistPath])
    {
        NSRunInformationalAlertPanel(@"Welcome to SilverService",
                                     @"As this is the first time you have used SilverService, it "
                                     @"has created you preferences. Open \"Preferences\" to add "
                                     @"services.\n\n"
                                     @"(For information, your preferences are in:\n\n"
                                     @"    ~/Library/Services/SilverService.service )",
                                     @"OK",nil,nil);

        NSString *cpath = [@"~/Library/" stringByExpandingTildeInPath];
        NSEnumerator *enumerator = [[NSArray arrayWithObjects: @"/Services",
            @"/SilverService.service",@"/Contents",nil] objectEnumerator];
        NSString *pathcomp;

        while (pathcomp = [enumerator nextObject]) {
            cpath = [cpath stringByAppendingString: pathcomp];
            [fm createDirectoryAtPath: cpath attributes: nil];
        };
        services = [[NSMutableDictionary alloc] init];
    }
    else
    {
        NSData *plistData;
        NSString *error;
        NSPropertyListFormat format;
        plistData = [NSData dataWithContentsOfFile:plistPath];

        id plist =
            [NSPropertyListSerialization propertyListFromData: plistData
                                             mutabilityOption:
                NSPropertyListMutableContainers
                                                       format: &format
                                             errorDescription: &error];
        if(!plist)
        {
            NSLog(error);
            [error release];
        }
        else
        {
            services = [[NSMutableDictionary alloc] init];
            NSEnumerator *enumerator =
                [[plist objectForKey: @"NSServices"] objectEnumerator];
            id s;
            while (s = [enumerator nextObject])
            {
                NSString *message = [s objectForKey: @"NSMessage"];
                if (![services objectForKey: message])
                    [services setObject: [[NSMutableArray alloc] init] forKey: message];
                [[services objectForKey: message] addObject:
                    [[s objectForKey: @"NSUserData"] propertyList]];
            }
        }
    }
}

-(void)updateOnDisk
{
    NSData *xmlData;
    NSString *error;

    NSMutableArray *servicelist = [[NSMutableArray alloc] init];
    NSDictionary *plist = [NSDictionary dictionaryWithObject: servicelist
                                                      forKey: @"NSServices"];

    NSEnumerator *messageEnum = [services keyEnumerator], *serviceEnum;
    NSMutableDictionary *serviceSpec;
    id message;
    while (message = [messageEnum nextObject])
    {
        NSMutableArray *mservices = [services objectForKey: message];
        NSDictionary *service;
        serviceEnum = [mservices objectEnumerator];
        while (service = [serviceEnum nextObject])
        {
            serviceSpec = [[NSMutableDictionary alloc] init];
            [serviceSpec setObject: @"SilverService" forKey: @"NSPortName"];
            [serviceSpec setObject: message forKey: @"NSMessage"];
            [serviceSpec setObject:
                [NSDictionary dictionaryWithObject: [@"SilverService/" stringByAppendingString: [service objectForKey: @"name"]]
                                            forKey: @"default"]
                            forKey: @"NSMenuItem"];
            if (![[service objectForKey: @"in"] isEqualToString: @"none"])
                [serviceSpec setObject: [NSArray arrayWithObject: @"NSStringPboardType"]
                                forKey: @"NSSendTypes"];
            if ([[service objectForKey: @"out"] isEqualToString: @"service"])
                [serviceSpec setObject: [NSArray arrayWithObject: @"NSStringPboardType"]
                                forKey: @"NSReturnTypes"];

            [serviceSpec setObject: [service description] forKey: @"NSUserData"];
            
            [servicelist addObject: serviceSpec];
        }
    }
    
    xmlData =
        [NSPropertyListSerialization dataFromPropertyList:plist
                                                   format:NSPropertyListXMLFormat_v1_0
                                         errorDescription:&error];
    if(xmlData)
    {
        [xmlData writeToFile:plistPath atomically:YES];
        NSUpdateDynamicServices();
    }
    else
    {
        NSLog(error);
        [error release];
    }
}

-(NSArray *)servicesOfType:(NSString*)type
{
    if (![services objectForKey: type])
    {
        [services setObject: [[NSMutableArray alloc] init] forKey: type];
    }
    return [services objectForKey: type];
}
@end
