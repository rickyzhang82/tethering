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

#import "SocksProxyController.h"
#import "AppDelegate.h"
#import "UIDevice_Extended.h"
#import "MOGlassButton.h"

#import <AVFoundation/AVFoundation.h>
#include <CFNetwork/CFNetwork.h>
#include <SafariServices/SafariServices.h>

#include <sys/socket.h>
#include <unistd.h>
#include <netinet/in.h>

@interface SocksProxyController () <SFSafariViewControllerDelegate>

// Properties that don't need to be seen by the outside world.

@property (nonatomic, readonly) BOOL                isStarted;
@property (nonatomic, strong)   NSNetService *      netService;
@property (nonatomic, assign)   CFSocketRef         listeningSocket;
@property (nonatomic, assign)   NSInteger			nConnections;
@property (nonatomic, strong) NSMutableArray*       sendreceiveStream;
@property (nonatomic, strong) AVPlayer*             bgPlayer;

// Forward declarations

- (void)_stopServer:(NSString *)reason;

@end

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

@implementation SocksProxyController
@synthesize nConnections  = _nConnections;
// Because sendreceiveStream is declared as an array, you have to use a custom getter.  
// A synthesised getter doesn't compile.
@synthesize bgPlayer;


- (NSMutableArray*)sendreceiveStream
{
    if(_sendreceiveStream == nil)
        _sendreceiveStream = [[NSMutableArray alloc]init];
    return _sendreceiveStream;
}


#pragma mark - Status management

// These methods are used by the core transfer code to update the UI.

- (void)_serverDidStartOnPort:(int)port
{
    assert( (port > 0) && (port < 65536) );

	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	// Disable device sleep mode
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	// Enable proximity sensor (public as of 3.0)
	[UIDevice currentDevice].proximityMonitoringEnabled = YES;
    
    // Enable backgrounding
    // Set AVAudioSession
    NSError *sessionError = nil;
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&sessionError];
    #else
        NSLog(@"Warning: iOS 6 is required for background audio hiding.");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    #endif
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[[NSBundle mainBundle] URLForResource:@"silence" withExtension:@"mp3"]];

    [self setBgPlayer:[[AVPlayer alloc] initWithPlayerItem:item]];
    [[self bgPlayer] setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    [[self bgPlayer] play];
	
	self.currentAddress = [UIDevice localWiFiIPAddress];
	self.currentPort = port;
	self.currentStatusText = NSLocalizedString(@"Started", nil);	
    [self.startOrStopButton setTitle:NSLocalizedString(@"Stop", nil)
							forState:UIControlStateNormal];
	[self.startOrStopButton setupAsRedButton];
	
	[self refreshProxyTable];
	
	LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_INFO, @"Server Started");
}

- (void)_serverDidStopWithReason:(NSString *)reason
{
    if (reason == nil) {
        reason = NSLocalizedString(@"Stopped", nil);
    }
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	// Enable device sleep mode
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	
	// Disable proximity sensor (public as of 3.0)
	[UIDevice currentDevice].proximityMonitoringEnabled = NO;
    
    // Disable backgrounding
    [self setBgPlayer:nil];
	
	self.currentAddress = @"";
	self.currentPort = 0;
	self.currentStatusText = reason;
    [self.startOrStopButton setTitle:NSLocalizedString(@"Start" , nil)
							forState:UIControlStateNormal];
	[self.startOrStopButton setupAsGreenButton];

	[self refreshProxyTable];

	LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_INFO, @"Server Stopped: %@", reason);
}


- (NSInteger)countOpen
{
	int countOpen = 0;
    for(SocksProxy* asocksProxy in self.sendreceiveStream)
	{
        if ( ! [asocksProxy isSendingReceiving])
			++countOpen;
	}
	return countOpen;
}


- (void)_sendreceiveDidStart
{
    self.currentStatusText = NSLocalizedString(@"Receiving", nil);
	
	NSInteger countOpen = [self countOpen];
	self.currentOpenConnections = countOpen;
	
	if (!countOpen) {
		[[AppDelegate sharedAppDelegate] didStartNetworking];
	}
	
	[self refreshProxyTable];
}


- (void)_updateStatus:(NSString *)statusString
{
    assert(statusString != nil);

	self.currentStatusText = statusString;

	LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_DEBUG, @"Status: %@", statusString);

}


- (void)_sendreceiveDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        statusString = NSLocalizedString(@"Receive succeeded", nil);
    }
	self.currentStatusText = statusString;
	NSInteger countOpen = [self countOpen];
	self.currentOpenConnections = countOpen;
	if (!countOpen) {
		[[AppDelegate sharedAppDelegate] didStopNetworking];		
	}

	[self refreshProxyTable];
	
	LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_INFO, @"Connection ended %ld %ld: %@", (long)countOpen, (long)self.nConnections, statusString);
}


- (void)_downloadData:(NSInteger)bytes
{
    self.downloadData += bytes/1024;
	
	[self refreshProxyTable];
}


- (void)_uploadData:(NSInteger)bytes
{
    self.uploadData += bytes/1024;
	
	[self refreshProxyTable];
}
#pragma mark - Core transfer code

// This is the code that actually does the networking.

@synthesize netService      = _netService;
@synthesize listeningSocket = _listeningSocket;


- (BOOL)isStarted
{
    return (self.netService != nil);
}

// Have to write our own setter for listeningSocket because CF gets grumpy 
// if you message NULL.

- (void)setListeningSocket:(CFSocketRef)newValue
{
    if (newValue != self->_listeningSocket) {
        if (self->_listeningSocket != NULL) {
            CFRelease(self->_listeningSocket);
        }
        self->_listeningSocket = newValue;
        if (self->_listeningSocket != NULL) {
            CFRetain(self->_listeningSocket);
        }
    }
}


- (void)_acceptConnection:(int)fd
{
	SocksProxy *proxy = nil;
    BOOL isFoundFreeProxy = NO;
	int totalNumProxy = 0;
    
    for(proxy in self.sendreceiveStream)
    {
        if(![proxy isSendingReceiving])
        {
            isFoundFreeProxy = YES;
            break;
        }
        totalNumProxy++;
    }
	
	if(!isFoundFreeProxy) {
		if(totalNumProxy>MAX_CONNECTIONS) {
            LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_WARNNING, @"Reach maximum number of concurrent SOCKS connectionss.");
			close(fd);
			return;
		}
        
		proxy = [SocksProxy new];
        proxy.delegate = self;
        [self.sendreceiveStream addObject:proxy];
        
		++self.nConnections;
		self.currentConnectionCount = self.nConnections;
	}
    
    //recount open connection
	int countOpen = 0;
    
	for (SocksProxy* asocksProxy in self.sendreceiveStream)
	{
		if (![asocksProxy isSendingReceiving])
			++countOpen;
	}

	LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_INFO, @"Accept connection %d %ld", countOpen, (long)self.nConnections);

	if (![proxy startSendReceive:fd])
		close(fd);
	
	[self refreshProxyTable];
}


static void AcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
    // Called by CFSocket when someone connects to our listening socket.  
    // This implementation just bounces the request up to Objective-C.
{
    SocksProxyController *  obj;
    
    #pragma unused(type)
    assert(type == kCFSocketAcceptCallBack);
    #pragma unused(address)
    // assert(address == NULL);
    assert(data != NULL);
    
    obj = (__bridge SocksProxyController *) info;
    assert(obj != nil);

    #pragma unused(s)
    assert(s == obj->_listeningSocket);
    
    [obj _acceptConnection:*(int *)data];
}


- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
    // A NSNetService delegate callback that's called if our Bonjour registration 
    // fails.  We respond by shutting down the server.
    //
    // This is another of the big simplifying assumptions in this sample. 
    // A real server would use the real name of the device for registrations, 
    // and handle automatically renaming the service on conflicts.  A real 
    // client would allow the user to browse for services.  To simplify things 
    // we just hard-wire the service name in the client and, in the server, fail 
    // if there's a service name conflict.
{
    #pragma unused(sender)
    assert(sender == self.netService);
    #pragma unused(errorDict)
    
    [self _stopServer:@"Registration failed"];
}


- (void)_startServer
{
    BOOL        success;
    int         err;
    int         fd;
    int         junk;
    struct sockaddr_in addr;
    int         port;
    const int   on = 1;
	
	self.nConnections = 0;
    // Create a listening socket and use CFSocket to integrate it into our 
    // runloop.  We bind to port 0, which causes the kernel to give us 
    // any free port, then use getsockname to find out what port number we 
    // actually got.

    port = 0;
    
	fd = socket(AF_INET, SOCK_STREAM, 0);
	success = (fd != -1);

	if (success) {
        // set scoket to reuse port and ignore TIME_WAIT state
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
        
		memset(&addr, 0, sizeof(addr));
		addr.sin_len    = sizeof(addr);
		addr.sin_family = AF_INET;
		addr.sin_addr.s_addr = INADDR_ANY;
		
		int iport;
		int ports[] = {1080,3128,-1};
		for (iport = 0 ; ports[iport] >= 0 ; ++iport) {
			port=ports[iport];
			addr.sin_port   = htons(port);
			err = bind(fd, (const struct sockaddr *) &addr, sizeof(addr));
            success = (err == 0);
			if (success)
				break;
            else{
                LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_ERROR, @"Socks Server failed to bind port (%d), errono (%d)", port, errno);
            }
		}
	}
	if (success) {
		err = listen(fd, 5);
		success = (err == 0);
	}else{
        LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_ERROR, @"Socks Server failed to bind to address, errno(%d)", errno);
    }
    
	if (success) {
		socklen_t   addrLen;

		addrLen = sizeof(addr);
		err = getsockname(fd, (struct sockaddr *) &addr, &addrLen);
		success = (err == 0);
		
		if (success) {
			assert(addrLen == sizeof(addr));
			port = ntohs(addr.sin_port);
		}
	}else{
        LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_ERROR, @"Socks Server failed to listen, errno(%d)", errno);
    }
    
    if (success) {
        CFSocketContext context = { 0, (__bridge void*)self, NULL, NULL, NULL };
        
        self.listeningSocket = CFSocketCreateWithNative(
            NULL, 
            fd, 
            kCFSocketAcceptCallBack, 
            AcceptCallback, 
            &context
        );
        success = (self.listeningSocket != NULL);
        
        if (success) {
            CFRunLoopSourceRef  rls;
            
            CFRelease(self.listeningSocket);        // to balance the create

            fd = -1;        // listeningSocket is now responsible for closing fd

            rls = CFSocketCreateRunLoopSource(NULL, self.listeningSocket, 0);
            assert(rls != NULL);
            
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
            
            CFRelease(rls);
        }
    }

    // Now register our service with Bonjour.  See the comments in -netService:didNotPublish: 
    // for more info about this simplifying assumption.

    if (success) {
        self.netService = [[NSNetService alloc] initWithDomain:@""
                                                          type:@"_socks5._tcp."
                                                          name:@"iPhone"
                                                          port:port];
        success = (self.netService != nil);
    }
    if (success) {
        self.netService.delegate = self;
        
        [self.netService publishWithOptions:NSNetServiceNoAutoRename];
        
        // continues in -netServiceDidPublish: or -netService:didNotPublish: ...
    }
    
    // Clean up after failure.
    
    if ( success ) {
        assert(port != 0);
        [self _serverDidStartOnPort:port];
    } else {
        [self _stopServer:@"Start failed"];
        if (fd != -1) {
            junk = close(fd);
            assert(junk == 0);
        }
    }
}


- (void)_stopServer:(NSString *)reason
{
	for (SocksProxy* asocksProxy in self.sendreceiveStream)
	{
		if ([asocksProxy isSendingReceiving])
			[asocksProxy stopSendReceiveWithStatus:@"Cancelled"];
    }
	
    [self.sendreceiveStream removeAllObjects];
    
    if (self.netService != nil) {
        [self.netService stop];
        self.netService = nil;
    }
    if (self.listeningSocket != NULL) {
        CFSocketInvalidate(self.listeningSocket);
        self.listeningSocket = NULL;
    }
    [self _serverDidStopWithReason:reason];
}


#pragma mark - Actions

- (IBAction)startOrStopAction:(id)sender
{
    #pragma unused(sender)
    if (self.isStarted) {
        [self _stopServer:nil];
        _DNSServer = DNSServer::getInstance();
        _DNSServer->stopDNSServer();
        _HTTPServer = [HTTPServer sharedHTTPServerWithSocksProxyPort:currentPort];
        [_HTTPServer stop];
    } else {
        
        if(self.currentAddress == nil)
            self.currentAddress = [UIDevice localWiFiIPAddress];
        
        if(currentAddress != nil){
            //start socks proxy server
            [self _startServer];
            //start DNS server
            _DNSServer = DNSServer::getInstance();
            const char * ipv4Addr = [currentAddress cStringUsingEncoding:NSASCIIStringEncoding];
            _DNSServer->startDNSServer(0, ipv4Addr);
            //start HTTP server that advertise socks.pac
            _HTTPServer = [HTTPServer sharedHTTPServerWithSocksProxyPort:currentPort];
            HTTPServerState currentHTTPServerState = [_HTTPServer state] ;
            if (currentHTTPServerState == SERVER_STATE_IDLE ||
                currentHTTPServerState == SERVER_STATE_STOPPING)
                [_HTTPServer start];
        }else{
            
            [self _updateStatus:@"Please connect to wifi."];
            LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_WARNNING, @"No local IP can be retrieved. iPhone may not connect to wifi network\n");
        }
        
    }
	
	[self refreshProxyTable];
}


#pragma mark - View controller boilerplate

@synthesize currentPort;
@synthesize currentAddress;
@synthesize currentOpenConnections;
@synthesize currentConnectionCount;
@synthesize downloadData, uploadData;
@synthesize currentStatusText;//       = _statusLabel;
@synthesize startOrStopButton = _startOrStopButton;



- (void)refreshProxyTable
{
	[proxyTableView reloadData];
}


- (void)applicationDidEnterForeground:(NSNotification *)n
{
	LOG_NETWORK_SOCKS(NSLOGGER_LEVEL_DEBUG, @"refreshing ip address");
	
	// refresh the IP address, just in case
	self.currentAddress = [UIDevice localWiFiIPAddress];
	[self refreshProxyTable];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
        
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidEnterForeground:)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
    assert(self.startOrStopButton != nil);
    
	self.currentStatusText = NSLocalizedString(@"Tap Start to start the server", nil);
    
	[self.startOrStopButton setupAsGreenButton];
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.title = @"Tethering";
    
    // Add info button
    UIButton *infoLightButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    infoLightButton.tintColor = [UIColor whiteColor];
    [infoLightButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:infoLightButton];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    self.startOrStopButton = nil;
}


- (void)dealloc
{
    [self _stopServer:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Custom Methods

- (void)showInfo {
    NSString *URLString = @"https://github.com/rickyzhang82/tethering/wiki";
    if ([SFSafariViewController class] != nil) {
        // Use SFSafariViewController
        SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:URLString]];
        sfvc.delegate = self;
        sfvc.view.tintColor = [UIColor colorWithRed:0.082 green:0.492 blue:0.980 alpha:1.0];
        [self presentViewController:sfvc animated:YES completion:nil];
    } else {
        // Open in Mobile Safari
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
    }
}

#pragma mark - SFSafariViewController delegate methods
-(void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    // Load finished
}

-(void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // Done button pressed
}

#pragma mark - Table View Data Source Methods

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
                    detailText = [@(self.currentPort) stringValue];
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
                detailText = [@(self.currentOpenConnections) stringValue];
            }
                break;
                
            case (SocksProxyTableRowConnections):
            {
                text = @"count";
                detailText = [@(self.currentConnectionCount) stringValue];
            }
                break;
                
            case (SocksProxyTableRowDownload):
            {
                text = @"down";
                detailText = [@(self.downloadData) stringValue];
            }
                break;
                
            case (SocksProxyTableRowUpload):
            {
                text = @"up";
                detailText = [@(self.uploadData) stringValue];
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
    
    return cell;
}


@end
