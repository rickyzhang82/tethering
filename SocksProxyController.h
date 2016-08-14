//
//	SOCKS - SOCKS Proxy for iPhone
//	Copyright (C) 2009 Ehud Ben-Reuven
//	udi@benreuven.com
//
//	This program is free software; you can redistribute it and/or
//	modify it under the terms of the GNU General Public License
//	as published by the Free Software Foundation version 2.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software
//	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,USA.
//
//  Enhanced by Daniel Sachse on 10/30/10.
//  Copyright 2010 coffeecoding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocksProxy.h"
#import "HTTPServer.h"
#include "ttdnsd.h"
//Max concurrent coonections
#define MAX_CONNECTIONS 100

@class MOGlassButton;

@interface SocksProxyController : UITableViewController <SocksProxyDelegate, NSNetServiceDelegate>
{
    UILabel *                   _portLabel;
    UILabel *                   _addressLabel;
    UILabel *                   _statusLabel;
	UILabel *					_countOpenLabel;
	UILabel *					_nConnectionsLabel;
    MOGlassButton *                  _startOrStopButton;
    
    NSNetService *              _netService;
    CFSocketRef                 _listeningSocket;
	
	NSInteger				_nConnections;
	IBOutlet UITableView * proxyTableView;
	
@private
	NSString *currentStatusText;
    NSInteger currentPort;
    NSString *currentAddress;
    NSInteger currentOpenConnections;
    NSInteger currentConnectionCount;
    DNSServer * _DNSServer;
    HTTPServer * _HTTPServer;
    
}

@property (nonatomic, copy) NSString *currentStatusText;
@property (nonatomic, assign) NSInteger currentPort;
@property (nonatomic, copy) NSString *currentAddress;
@property (nonatomic, assign) NSInteger currentOpenConnections;
@property (nonatomic, assign) NSInteger currentConnectionCount;
@property (nonatomic, assign) NSInteger uploadData;
@property (nonatomic, assign) NSInteger downloadData;
@property (nonatomic, strong) IBOutlet MOGlassButton *                  startOrStopButton;

- (IBAction)startOrStopAction:(id)sender;

- (void)refreshProxyTable;
@end
