//
//  UIDevice_Extended.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIDevice (Reachability)
+ (NSString *)localWiFiIPAddress;
+ (BOOL)isNetworkAvailable;
+ (BOOL) activeWLAN;
+ (BOOL)hasActiveWWAN;
@end