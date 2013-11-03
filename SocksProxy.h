/*
 #  SOCKS - SOCKS Proxy for iPhone
 #  Copyright (C) 2009 Ehud Ben-Reuven
 #  udi@benreuven.com
 #
 # This program is free software; you can redistribute it and/or
 # modify it under the terms of the GNU General Public License
 # as published by the Free Software Foundation version 2.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with this program; if not, write to the Free Software
 # Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,USA.
 */
#import <UIKit/UIKit.h>

enum {
    kSendBufferSize = 100000,
    kReceiveBufferSize = 200000
};

@protocol SocksProxyDelegate <NSObject>
- (void)_updateStatus:(NSString *)statusString;
- (void)_sendreceiveDidStart;
- (void) _sendreceiveDidStopWithStatus:(NSString *)statusString;
- (void)_downloadData:(NSInteger)bytes;
- (void)_uploadData:(NSInteger)bytes;
@end

@interface SocksProxy : NSObject <NSStreamDelegate>
{
    NSInputStream *             _receivenetworkStream;
    NSOutputStream *             _sendnetworkStream;
    NSOutputStream *            _remoteSendNetworkStream;
    NSInputStream *             _remoteReceiveNetworkStream;
    id <SocksProxyDelegate> delegate;
    uint8_t                     _sendbuffer[kSendBufferSize];
    size_t                      _sendbufferOffset;
    size_t                      _sendbufferLimit;
    uint8_t                     _receivebuffer[kReceiveBufferSize];
    size_t                      _receivebufferOffset;
    size_t                      _receivebufferLimit;
	NSUInteger					_protocolLocation;
	NSString *					_remoteName;
}

@property (nonatomic, assign) id <SocksProxyDelegate> delegate;
@property (nonatomic, readonly) BOOL isSendingReceiving;

- (void)stopSendReceiveWithStatus:(NSString *)statusString;
- (BOOL)startSendReceive:(int)fd;

@end
