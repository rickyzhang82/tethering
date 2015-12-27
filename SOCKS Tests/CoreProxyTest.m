//
//  CoreProxyTest.m
//  SOCKS
//
//  Created by 
//
//

#import <XCTest/XCTest.h>

#import <sys/socket.h>

#import "SocksProxy.h"
#import "SocksProxy_protected.h"

@interface CoreProxyTest : XCTestCase

@end

@implementation CoreProxyTest

NSThread *proxyThread;
NSInputStream *fromProxyStream;
NSOutputStream  *toProxyStream;

- (void)setUp {
    [super setUp];
    
    //
    // Socket pair to simulate the client
    // We can write into client[0] and expect to be able
    // to read the same data back, via the proxy and the server
    //
    int client[2];
    
    // Connect the socketpair
    if (socketpair(PF_LOCAL, SOCK_STREAM, 0, client) != 0) {
        XCTAssert(NO, @"Failed to setup socket for the simulating the client (Error %d - %s)", errno, strerror(errno));
    }
    
    
    // Launch the proxy in its own thread
    proxyThread = [[NSThread alloc] initWithTarget:self selector:@selector(runProxyWithClientFd:) object:[NSNumber numberWithInt:client[1]]];
    [proxyThread start];
    
    
    // Open a stream based on the existing socket file descriptor.  Then configure
    // the stream for async operation.
    CFReadStreamRef   readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocket(NULL, client[0], &readStream, &writeStream);
    if(readStream == NULL || writeStream == NULL) {
        XCTAssert(NO, @"Failed to create socket pair");
    }
    
    fromProxyStream = (NSInputStream  *) CFBridgingRelease(readStream);
    toProxyStream   = (NSOutputStream *) CFBridgingRelease(writeStream);
    
    [fromProxyStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
    [toProxyStream   setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
    
    [fromProxyStream open];
    [toProxyStream   open];
    
}


- (void) tearDown {
    
    [super tearDown];
    
    [toProxyStream setDelegate:nil];
    [toProxyStream close];
    toProxyStream = nil;
    
    [fromProxyStream setDelegate:nil];
    [fromProxyStream close];
    fromProxyStream = nil;
    
    while ([proxyThread isExecuting]) {
        sleep(1);
    }
    
    NSLog(@"Proxy thread %@", [proxyThread isFinished] ? @"has finished" : @"still running");
}


- (void) runProxyWithClientFd:(NSNumber *) clientFd {
    
    SocksProxy *proxy = [SocksProxy new];
    
    // Setup the network (C>P and P>C) streams
    int fd = [clientFd intValue];
    if(![proxy startSendReceive:fd]) {
        XCTAssert(NO, @"Failed to start the proxy");
    }
    
    
    // Fake the server - just echo back the data that gets sent to it
    CFReadStreamRef  istream;
    CFWriteStreamRef ostream;
    
    CFStreamCreateBoundPair(NULL, &istream, &ostream, 4096 );
    
    [proxy setRemoteName:@"echo"];
    [proxy setRemoteReceiveNetworkStream:CFBridgingRelease(istream)];
    [proxy setRemoteSendNetworkStream:CFBridgingRelease(ostream)];
    
    
    // Pretend we have done the SOCKs negotiation
    [proxy setProtocolLocation:2];
    
    [[proxy remoteSendNetworkStream] setDelegate:proxy];
    [[proxy remoteSendNetworkStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[proxy remoteSendNetworkStream] open];
    
    [[proxy remoteReceiveNetworkStream] setDelegate:proxy];
    [[proxy remoteReceiveNetworkStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[proxy remoteReceiveNetworkStream] open];
    
    
    // Start the run loop
    [[NSRunLoop currentRunLoop] run];
    
    
    [[proxy remoteSendNetworkStream] setDelegate:nil];
    [[proxy remoteSendNetworkStream] close];
    [proxy setRemoteSendNetworkStream:nil];
    
    [[proxy remoteReceiveNetworkStream] setDelegate:nil];
    [[proxy remoteReceiveNetworkStream] close];
    [proxy setRemoteReceiveNetworkStream:nil];
    
    close(fd);
}


// Utility function to send data via the proxy
- (void)sendData:(NSInteger) dataSize fromBuffer:(const uint8_t *) fromBuffer toBuffer: (uint8_t *) toBuffer
{
    NSInteger bytesWritten = 0;
    NSInteger bytesRead = 0;
    NSInteger len;
    
    do {
        
        if( [toProxyStream hasSpaceAvailable] && bytesWritten < dataSize){
            len = [toProxyStream write:&fromBuffer[bytesWritten] maxLength:dataSize - bytesWritten];
            
            if(len < 0) {
                if (errno == EAGAIN){
                    continue;
                }
                
                XCTAssert(NO, @"Failed to write to proxy (Error %d - %s)", errno, strerror(errno));
            }
            
            bytesWritten += len;
        }
        
        if([fromProxyStream hasBytesAvailable]) {
            
            len = [fromProxyStream read:&toBuffer[bytesRead] maxLength:dataSize - bytesRead];
            
            if(len < 0) {
                
                if (errno == EAGAIN) {
                    continue;
                }
                
                XCTAssert(NO, @"Failed to read to proxy (Error %d - %s)", errno, strerror(errno));
            }
            
            bytesRead += len;
        }
        
    } while (bytesRead < dataSize);
}


- (void)testProxyDataTransfer {
    
    NSInteger dataSize = 10 * 1024 * 1024;
    
    uint8_t *data = malloc(dataSize);
    uint8_t *buf = malloc(dataSize);
    
    
    for (int i= 0; i< 10; i++) {
        
        int fd = open("/dev/urandom", O_RDONLY);
        read(fd, data, dataSize);
        
        [self sendData:dataSize fromBuffer:data toBuffer:buf];
        
        if (memcmp(data, buf, dataSize) != 0) {
            XCTAssert(NO, @"Fail - Data sent on round %u does not match data recieved.", i);
            
            free(data);
            free(buf);
            return;
        }
    }
    
    XCTAssert(YES, @"Pass - Data sent matches data recieved.");
    
    free(data);
    free(buf);
}


- (void)testProxySpeed {
    
    // Amount of data to transfer in this performance test
    NSInteger dataSize = 10 * 1024 * 1024;
    
    uint8_t *data = malloc(dataSize);
    uint8_t *buf = malloc(dataSize);
    
    int fd = open("/dev/urandom", O_RDONLY);
    read(fd, data, dataSize);
    
    [self measureBlock:^{
        [self sendData:dataSize fromBuffer:data toBuffer:buf];
    }];
    
    if (memcmp(data, buf, dataSize) == 0) {
        XCTAssert(YES, @"Pass - Data sent matches data recieved.");
        
        free(data);
        free(buf);
        return;
    }
    
    free(data);
    free(buf);
    
    XCTAssert(NO, @"Fail - Data sent does not match data recieved.");
    
}

@end
