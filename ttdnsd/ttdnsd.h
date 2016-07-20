/*
 *  The Tor TCP DNS Daemon
 *
 *  Copyright (c) Collin R. Mulliner <collin(AT)mulliner.org>
 *  Copyright (c) 2010, The Tor Project, Inc.
 *
 */


#ifndef TTDNSDH
#define TTDNSDH


#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <getopt.h>
#include <time.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/poll.h>
#include <netinet/in.h>
#include <netdb.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <limits.h>
#include <pthread.h>
#include "ttdnsd_platform.h"

#ifdef NOT_HAVE_COCOA_FRAMEWORK
#include <stdarg.h>
#include "../NSLogger/LogLevel.h"
#endif


const char TTDNSD_VERSION[]= "v1.0";

// number of parallel connected tcp peers
const int MAX_PEERS = 1;
// request timeout
const int MAX_TIME = 3; /* QUASIBUG 3 seconds is too short! */
// number of trys per request (not used so far)
const int MAX_TRY = 1;
// maximal number of nameservers
const int MAX_NAMESERVERS = 32;
// request queue size (use a prime number for hashing)
const int MAX_REQUESTS = 499;
// 199, 1009
// max line size for configuration processing
const int MAX_LINE_SIZE = 1025;
//maximum lenght of IPV4 address
const int MAX_IPV4_ADDR_LENGTH = 20;
//maximum TCP fd write retry times
const int MAX_TCP_WRITE_TIME = 10;

// Magic numbers
const int RECV_BUF_SIZE = 1502;

const int NOBODY = 65534;
const int NOGROUP = 65534;
const int DEFAULT_DNS_PORT = 53;
const char DEFAULT_DNS_IP[]= "8.8.8.8";
const int DEFAULT_BIND_PORT = 53;
const char DEFAULT_BIND_IP[]= "127.0.0.1";
const char DEFAULT_SOCKS5_IP[]= "192.168.1.3";
const int DEFAULT_SOCKS5_PORT = 1080;
const char MAGIC_STRING_STOP_DNS[] = "Time for home!";
const char DEFAULT_MAGIC_IPV4_ADDR[] = "0.0.0.0";

#define HELP_STR ""\
    "syntax: ttdnsd [bpfPCcdlhV]\n"\
    "\t-b\t<local ip>\tlocal IP to bind to\n"\
    "\t-p\t<local port>\tbind to port\n"\
    "\t-f\t<resolvers>\tfilename to read resolver IP(s) from\n"\
    "\t-P\t<PID file>\tfile to store process ID - pre-chroot\n"\
    "\t-C\t<chroot dir>\tchroot(2) to <chroot dir>\n"\
    "\t-c\t\t\tDON'T chroot(2) to /var/lib/ttdnsd\n"\
    "\t-d\t\t\tDEBUG (don't fork and print debug)\n"\
    "\t-l\t\t\twrite debug log to: " DEFAULT_LOG "\n"\
    "\t-h\t\t\tprint this helpful text and exit\n"\
    "\t-V\t\t\tprint version and exit\n\n"\
    "export TSOCKS_CONF_FILE to point to config file inside the chroot\n"\
    "\n"
typedef enum{
    DNS_SERVER_STARTING = 0,
    DNS_SERVER_STARTED,
    DNS_SERVER_TERMINATING,
    DNS_SERVER_TERMINATED
} DNS_SERVER_STATE;

typedef enum {
    DEAD = 0,
    CONNECTING,
    CONNECTING2,
    CONNECTED,
    SOCKS5_CONNECTING,
    SOCKS5_AUTH_WAIT,
    SOCKS5_CMD_WAIT
} CON_STATE;

typedef enum {
    WAITING = 0,
    SENT
} REQ_STATE;

struct request_t {
    struct sockaddr_in a; /* client’s IP/port */
    socklen_t al;
    unsigned char b[1502]; /**< request buffer */
    int bl; /**< bytes in request buffer */
    uint id; /**< dns request id */
    int rid; /**< real dns request id */
    REQ_STATE active; /**< 1=sent, 0=waiting for tcp to become connected */
    time_t timeout; /**< timeout of request */
};

struct peer_t
{
    struct sockaddr_in tcp;
    struct sockaddr_in socks5_tcp;
    int tcp_fd;
    time_t timeout;
    CON_STATE con; /**< connection state 0=dead, 1=connecting..., 3=connected */
    unsigned char b[RECV_BUF_SIZE]; /**< receive buffer */
    int bl; /**< bytes in receive buffer */ // bl? Why don't we call this bytes_in_recv_buf or something meaningful?
};

class DNSServer{

public:
    
    static DNSServer* getInstance(){
       
        if(dns_instance == NULL)
            
            dns_instance = new DNSServer();
        
        return dns_instance;
    }
    
    ~DNSServer();
    /*Start DNS server in posix thread*/
    int startDNSServer(int _isDebugMode = 1,
                       const char* _localDNSIP = DEFAULT_MAGIC_IPV4_ADDR,
                       const char* _remoteDNSIP = DEFAULT_DNS_IP,
                       int _localDNSPort = DEFAULT_BIND_PORT,
                       int _remoteDNSPort = DEFAULT_DNS_PORT,
                       time_t _remoteDNSTimeout = MAX_TIME,
                       int _isSockify = 0,
                       const char* _remoteSockProxyIP = DEFAULT_SOCKS5_IP,
                       int _remoteSockProxyPort = DEFAULT_SOCKS5_PORT);

    void stopDNSServer();

    void stopDNSServer(const char* localDNSIP);

    DNS_SERVER_STATE getDNSServerState();

protected:

    DNSServer();

    const char * peer_display(struct peer_t *p);
    int peer_connect(struct peer_t *p, struct in_addr ns);
    int peer_connected(struct peer_t *p);
    int peer_sendreq(struct peer_t *p, struct request_t *r);
    int peer_readres(struct peer_t *p);
    void peer_mark_as_dead(struct peer_t *p);
    void peer_handleoutstanding(struct peer_t *p);

    struct peer_t *peer_select(void);
    struct in_addr ns_select(void);

    int request_find(uint id);
    int request_add(struct request_t *r);
    int _start_server();
    void _stop_server();
    int _nonblocking_send(int fd, void* buff, int len);
    void process_incoming_request(struct request_t *tmp);

    const char *  peer_socks5_display(struct peer_t *p);
    int peer_socks5_connect(struct peer_t *p, struct in_addr socks5_addr, struct in_addr ns_addr);
    int peer_socks5_connected(struct peer_t *p);
    int peer_socks5_snd_auth_neg(struct peer_t *p);
    int peer_socks5_rcv_auth_process(struct peer_t *p);
    int peer_socks5_snd_cmd(struct peer_t *p);
    int peer_socks5_rcv_cmd_process(struct peer_t *p);    
    struct in_addr socks5_proxy_select(void);

    #ifndef NOT_HAVE_COCOA_FRAMEWORK
    int print_level(int level, const char * __restrict format, ...);
    #endif
    
    static void * _dns_srv_thread_wrapper(void*){
        
        DNSServer * dns_srv = DNSServer::getInstance();
        
        dns_srv->_start_server();
        
        return 0;
    }

    struct in_addr nameservers; /**< nameservers pool */

    struct peer_t peers[MAX_PEERS]; /**< TCP peers */
    struct request_t requests[MAX_REQUESTS]; /**< request queue */
    int udp_fd; /**< port 53 socket */

    int isSockify; /*Flag to determine if TCP should be sockify*/

    char *remoteSocksIP;

    int remoteSocksPort;

    char *remoteDNSIP;

    int remoteDNSPort;

    char *localDNSIP;

    int localDNSPort;

    int isDebugMode;

    time_t remoteDNSTimeout;
    
    static DNSServer * dns_instance;

    volatile DNS_SERVER_STATE dnsState;
    
};

#endif


