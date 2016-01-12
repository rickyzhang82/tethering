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

#ifndef SOCKS_SocksProxy_Private_h
#define SOCKS_SocksProxy_Private_h

@interface SocksProxy ()
- (void)socksProtocol;

// Properties that don't need to be seen by the outside world.

@property (nonatomic, strong)   NSInputStream *     receivenetworkStream;
@property (nonatomic, strong)   NSOutputStream *    sendnetworkStream;
@property (nonatomic, strong)   NSOutputStream *    remoteSendNetworkStream;
@property (nonatomic, strong)   NSInputStream *     remoteReceiveNetworkStream;
@property (nonatomic, readonly) uint8_t *           sendbuffer;
@property (nonatomic, assign)   size_t              sendbufferOffset;
@property (nonatomic, assign)   size_t              sendbufferLimit;
@property (nonatomic, readonly) uint8_t *           receivebuffer;
@property (nonatomic, assign)   size_t              receivebufferOffset;
@property (nonatomic, assign)   size_t              receivebufferLimit;
@property (nonatomic, assign)   NSUInteger			protocolLocation;
@property (nonatomic, strong)   NSString *			remoteName;

@end

#endif
