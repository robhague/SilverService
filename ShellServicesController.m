// ShellServicesController.h
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

#import "ShellServicesController.h"


@implementation ShellServicesController

- (void) awakeFromNib
{
    inputTypes = [[NSArray arrayWithObjects: @"none", @"stdin", @"string", nil] retain];
    outputTypes = [[NSArray arrayWithObjects: @"none", @"panel", @"service", nil] retain];

    /* Input Cell */
    NSPopUpButtonCell *popupButtonCell;
    popupButtonCell = [[[NSPopUpButtonCell alloc] initTextCell: @""
                                                     pullsDown: NO] autorelease];
    [popupButtonCell setEditable:YES];
    [popupButtonCell setBordered:NO];
    [popupButtonCell addItemsWithTitles: inputTypes];
    [[theTable tableColumnWithIdentifier:@"in"] setDataCell:popupButtonCell];

    /* Output Cell */
    popupButtonCell = [[[NSPopUpButtonCell alloc] initTextCell: @""
                                                     pullsDown: NO] autorelease];
    [popupButtonCell setEditable:YES];
    [popupButtonCell setBordered:NO];
    [popupButtonCell addItemsWithTitles: outputTypes];
    [[theTable tableColumnWithIdentifier:@"out"] setDataCell:popupButtonCell];
}

- (id)          tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
                      row:(int)rowIndex
{
    NSDictionary *service =
    [[bundle servicesOfType: @"shellService"] objectAtIndex: rowIndex];
    NSString *value = [service objectForKey: [tableColumn identifier]];
    if ([[tableColumn identifier] isEqualToString:@"in"])
        return [NSNumber numberWithInt:[inputTypes indexOfObject: value]];
    if ([[tableColumn identifier] isEqualToString:@"out"])
        return [NSNumber numberWithInt:[outputTypes indexOfObject: value]];
    return value;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[bundle servicesOfType: @"shellService"] count];
}

-(void)             tableView:(NSTableView *)tableView
               setObjectValue:(id)object
               forTableColumn:(NSTableColumn *)tableColumn
                          row:(int)row
{
    NSMutableDictionary *service =
        [[bundle servicesOfType: @"shellService"] objectAtIndex: row];
    NSString *value;
    if ([[tableColumn identifier] isEqualToString:@"in"])
        value = [inputTypes objectAtIndex: [object intValue]];
    else if ([[tableColumn identifier] isEqualToString:@"out"])
        value = [outputTypes objectAtIndex: [object intValue]];
    else
        value = object;
    [service setObject: value forKey: [tableColumn identifier]];
    [bundle updateOnDisk];
}

-(IBAction)newService:(id)sender
{
    NSMutableDictionary *newService =
    [@"{name=\"New Service\"; in=stdin; out=service; command=\"\";}" propertyList];
    [[bundle servicesOfType: @"shellService"] addObject: newService];
    [theTable setNeedsDisplay: YES];
    [bundle updateOnDisk];
}

-(IBAction)deleteService:(id)sender
{
    int index = [theTable selectedRow];
    if (index != -1)
    {
        [[bundle servicesOfType: @"shellService"] removeObjectAtIndex: index];
        [theTable setNeedsDisplay: YES];
        [bundle updateOnDisk]; 
    }
}
@end
