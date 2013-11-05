//
//  SocksProxyController_TableView.m
//  SOCKS
//
//  Created by C. Bess on 9/5/10.
//  Copyright 2010 Christopher Bess. All rights reserved.
//
//  Enhanced by Daniel Sachse on 10/30/10.
//  Copyright 2010 coffeecoding. All rights reserved.
//

#import "SocksProxyController_TableView.h"

/*!
 * Specifies the sections of the table
 */
typedef enum {
	SocksProxyTableSectionGeneral,
	SocksProxyTableSectionConnections,
	SocksProxyTableSectionCount
} SocksProxyTableSection;

/*!
 * Specifies the rows of the table sections
 */
typedef enum {
	SocksProxyTableRowAddress,
	SocksProxyTableRowPort,
	// connections section
	SocksProxyTableRowConnections = 0,
	SocksProxyTableRowConnectionsOpen,
    SocksProxyTableRowUpload,
	SocksProxyTableRowDownload,
	SocksProxyTableRowStatus
} SocksProxyTableRow;

@implementation SocksProxyController (TableView)

#pragma mark Table View Data Source Methods

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section
{	
	#pragma unused(table)
	/*
	if (section == SocksProxyTableSectionConnections)
		return @"Connections";
	*/
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table
{
	#pragma unused(table)
	
    return SocksProxyTableSectionCount;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section 
{	
	#pragma unused(table)
	
	switch (section)
	{
		case SocksProxyTableSectionGeneral:
			return 2;
			
		case SocksProxyTableSectionConnections:
			return 5;
	}
	
	return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	//cell.selected = NO;
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	#pragma unused(table)
	static NSString * cellId = @"cellid";
	
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
												   reuseIdentifier:cellId];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.accessoryView = nil;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
	NSString *text = nil; // the caption
	NSString *detailText = nil;
	
	switch (indexPath.section)
	{
		case (SocksProxyTableSectionGeneral):
			switch (indexPath.row)
			{
				case (SocksProxyTableRowAddress):
				{
					text = @"address";
					detailText = self.currentAddress;
					if (self.currentAddress.length == 0)
						detailText = @"n/a";
				}
				break;
					
				case (SocksProxyTableRowPort):
				{
					text = @"port";
					if (self.currentPort)
						detailText = [[NSNumber numberWithInt:self.currentPort] stringValue];
					else
						detailText = @"n/a";
				}
				break;
			}
			break;
			
		case (SocksProxyTableSectionConnections):
			switch (indexPath.row)
			{
				case (SocksProxyTableRowConnectionsOpen):
				{
					text = @"open";
					detailText = [[NSNumber numberWithInt:self.currentOpenConnections] stringValue];
				}
				break;
					
				case (SocksProxyTableRowConnections):
				{
					text = @"count";
					detailText = [[NSNumber numberWithInt:self.currentConnectionCount] stringValue];
				}
				break;
					
				case (SocksProxyTableRowDownload):
				{
					text = @"down";
					detailText = [[NSNumber numberWithInt:self.downloadData] stringValue];
				}
				break;

				case (SocksProxyTableRowUpload):
				{
					text = @"up";
					detailText = [[NSNumber numberWithInt:self.uploadData] stringValue];
				}
				break;
					
				case (SocksProxyTableRowStatus):
				{
					text = @"status";
					detailText = self.currentStatusText;
				}
				break;
			}
			break;
	}
	
	// set the field label title
    cell.textLabel.text = text;
	
	// set the cell text
    cell.detailTextLabel.text = detailText;
	
	return [cell autorelease];
}

@end
