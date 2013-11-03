/*
    File:       AppDelegate.m

    Contains:   Main app controller.

    Written by: DTS

    Copyright:  Copyright (c) 2009 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "AppDelegate.h"
#import "InfoController.h"
#import "SocksProxyController.h"

/// background timer task constants
// converts mins to seconds
#define MINS(N) N * 60
// number of minutes until the critical or warning UIAlert is displayed
#define PROXY_BG_TIME_WARNING_MINS 1
// interval of seconds to poll/check the time remaining for the background task
#define PROXY_BG_TIME_CHECK_SECS 5

@interface AppDelegate ()
@property (nonatomic, assign) NSInteger networkingCount;
@end

@implementation AppDelegate

+ (AppDelegate *)sharedAppDelegate
{
    return (AppDelegate *) [UIApplication sharedApplication].delegate;
}

@synthesize window = _window;
@synthesize tabs = _tabs;
@synthesize viewController = _viewController;

@synthesize networkingCount = _networkingCount;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    #pragma unused(application)
    assert(self.window != nil);
    
    [self.window addSubview:self.viewController.view];
    
    
	[self.window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    #pragma unused(application)
	
	// Reenable device sleep mode on exit
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	
    [[NSUserDefaults standardUserDefaults] setInteger:self.tabs.selectedIndex forKey:@"currentTab"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DLog(@"%s", __func__);

	// if no networking, then ignore the bg operations

	_warningTimeAlertShown = NO;
	_bgTimer = [NSTimer scheduledTimerWithTimeInterval:PROXY_BG_TIME_CHECK_SECS
												target:self
											  selector:@selector(checkBackgroundTimeRemaining:)
											  userInfo:nil
											   repeats:YES];
    __block UIBackgroundTaskIdentifier ident;
	
    ident = [application beginBackgroundTaskWithExpirationHandler: ^{
        DLog(@"Background task expiring!");
		
        [application endBackgroundTask: ident];
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	application.applicationIconBadgeNumber = 0;
	[application cancelAllLocalNotifications];
	[_bgTimer invalidate];
}

- (void)didStartNetworking
{
    self.networkingCount += 1;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didStopNetworking
{
	if (self.networkingCount > 0)
		self.networkingCount -= 1;
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = (self.networkingCount > 0);
}

- (void)checkBackgroundTimeRemaining:(NSTimer *)timer
{
	// if no networking, then ignore the bg operations
	if ([UIApplication sharedApplication].networkActivityIndicatorVisible == FALSE)
		return;
	
	NSTimeInterval timeLeft = [UIApplication sharedApplication].backgroundTimeRemaining;
	
	DLog(@"Background time remaining: %.0f seconds (~%d mins)", timeLeft, (int)timeLeft / 60);

	UILocalNotification *badge = nil;
	badge = [UILocalNotification new];
	[badge setApplicationIconBadgeNumber:(int)timeLeft/60];
	[[UIApplication sharedApplication] presentLocalNotificationNow:badge];
	[badge release];
	if (timeLeft < MINS(1))
	{
		[UIApplication sharedApplication].applicationIconBadgeNumber = 0;
	}
	
	UILocalNotification *notif = nil;

	// check the critical and warning thresholds
	if (timeLeft < MINS(PROXY_BG_TIME_WARNING_MINS)
		&& !_warningTimeAlertShown)
	{
		NSString *msg = NSLocalizedString(@"Your connection will be closed immediately", nil);
		DLog(msg,nil);
		
		// build the UIAlert to be displayed
		notif = [UILocalNotification new];
		notif.alertBody = [NSString stringWithFormat:msg, PROXY_BG_TIME_WARNING_MINS];
		notif.soundName = UILocalNotificationDefaultSoundName;
		
		_warningTimeAlertShown = YES;
	}
 
	if (notif) 
	{		
		notif.alertAction = NSLocalizedString(@"Renew", nil);
		
		// show the alert immediately
		[[UIApplication sharedApplication] presentLocalNotificationNow:notif];
		[notif release];
	}
}
@end
