/*
 *  The Tor TCP DNS Daemon
 *
 *  Copyright (c) Collin R. Mulliner <collin(AT)mulliner.org>
 *  Copyright (c) 2010, The Tor Project, Inc.
 *
 *  http://www.mulliner.org/collin/ttdnsd.php
 *  https://www.torproject.org/ttdnsd/
 *
 */
/*
 *  Feature enhancement:
 *  1. Add simple socks5 support. Sockify TCP connection to DNS
 *  2. Moduleze ttdns called by socks proxy
 *  3. Encasuplate interface in C++ class
 */

#include "ttdnsd.h"

/*
 *  Binary is linked with libtsocks therefore all TCP connections will
 *  be routed over Tor (if tsocks.conf is set up to chain with Tor).
 *
 *  See Makefile about disabling tsocks (for testing).
 *
 */

DNSServer * DNSServer::dns_instance = NULL;

#ifdef NOT_HAVE_COCOA_FRAMEWORK
// for testing in *nix
int print_level(int level, const char * format, ...)
{
    va_list args;
    va_start(args,format);
    if (level == NSLOGGER_LEVEL_ERROR)
        return vfprintf(stderr, format, args);
    else
        return vprintf(format, args);
}

#else
// for iOS
int DNSServer::print_level(int level, const char * __restrict format, ...)
{
    va_list args;
    va_start(args,format);
    LOG_NETWORK_DNS_VA(level, @(format), args);
    va_end(args);
    return 1;
}

#endif


DNS_SERVER_STATE DNSServer::getDNSServerState()
{
    return this->dnsState;
}

DNSServer::DNSServer()
{
    this->isDebugMode = 0;

    this->remoteDNSIP = new char[MAX_IPV4_ADDR_LENGTH];
    memset(this->remoteDNSIP, 0, MAX_IPV4_ADDR_LENGTH);
    strcpy(this->remoteDNSIP, DEFAULT_DNS_IP),
    this->remoteDNSPort = DEFAULT_DNS_PORT;

    this->localDNSIP = new char[MAX_IPV4_ADDR_LENGTH];
    memset(this->localDNSIP, 0, MAX_IPV4_ADDR_LENGTH);
    strcpy(this->localDNSIP, DEFAULT_MAGIC_IPV4_ADDR);
    this->localDNSPort = DEFAULT_BIND_PORT;

    this->isSockify = 0;

    this->remoteSocksIP = new char[MAX_IPV4_ADDR_LENGTH];
    memset(this->remoteSocksIP, 0, MAX_IPV4_ADDR_LENGTH);    
    strcpy(this->remoteSocksIP, DEFAULT_SOCKS5_IP);
    this->remoteSocksPort = DEFAULT_SOCKS5_PORT;

    this->dnsState = DNS_SERVER_TERMINATED;

    this->remoteDNSTimeout = MAX_TIME;

}

DNSServer::~DNSServer()

{
    delete this->remoteDNSIP;
    delete this->remoteSocksIP;
    delete this->localDNSIP;
}

int DNSServer::startDNSServer(int _isDebugMode,
                              const char* _localDNSIP,
                              const char* _remoteDNSIP,
                              int _localDNSPort,
                              int _remoteDNSPort,
                              time_t _remoteDNSTimeout,
                              int _isSockify,
                              const char* _remoteSockProxyIP,
                              int _remoteSockProxyPort)
{

    this->dnsState = DNS_SERVER_STARTING;

    this->remoteDNSTimeout = _remoteDNSTimeout;

    this->isSockify = _isSockify;

    this->isDebugMode = _isDebugMode;

    if(_isSockify){

        this->remoteSocksPort = _remoteSockProxyPort;

        memset(this->remoteSocksIP, 0,MAX_IPV4_ADDR_LENGTH);

        strcpy(this->remoteSocksIP,_remoteSockProxyIP);

    }

    in_addr_t ns;

    if(inet_pton(AF_INET, _remoteDNSIP, &ns)){

        nameservers.s_addr = ns;

        memset(this->remoteDNSIP, 0, MAX_IPV4_ADDR_LENGTH);

        strcpy(this->remoteDNSIP, _remoteDNSIP);

    }else{

        print_level(NSLOGGER_LEVEL_ERROR, "%s: is not a valid IPv4 address for DNS server.\n", remoteSocksIP);

        return -1;
    }

    this->remoteDNSPort = _remoteDNSPort;

    memset(this->localDNSIP, 0, MAX_IPV4_ADDR_LENGTH);

    strcpy(this->localDNSIP, _localDNSIP);

    this->localDNSPort = _localDNSPort;

    print_level(NSLOGGER_LEVEL_INFO, "Starting DNS server...\n");

    if(_isDebugMode){

        return _start_server();

    }else{
        //create a new thread.
        pthread_t * rs_thread = new pthread_t;
        
        pthread_attr_t rs_attr;

        pthread_attr_init(&rs_attr);

        pthread_attr_setdetachstate(&rs_attr, PTHREAD_CREATE_DETACHED);

        if(pthread_create(rs_thread, &rs_attr, _dns_srv_thread_wrapper, NULL) == 0){

            print_level(NSLOGGER_LEVEL_INFO, "DNS server thread is created.\n");

            pthread_attr_destroy(&rs_attr);
            
            delete rs_thread;

            return 0;
        }else{

            print_level(NSLOGGER_LEVEL_ERROR, "Failed to create DNS server thread.\n");

            this->dnsState = DNS_SERVER_TERMINATED;

            pthread_attr_destroy(&rs_attr);
            
            delete rs_thread;

            return -1;
        }
    }
}

void DNSServer::stopDNSServer(const char* _localDNSIP)
{
    //send magic string to DNS server
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in  addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(this->localDNSPort);



    if(!inet_aton(_localDNSIP, &addr.sin_addr)){
        print_level(NSLOGGER_LEVEL_ERROR, "Invalid IPv4 address for DNS server.\n Failed to terminate DNS server.\n");
    }

    sendto(sockfd, MAGIC_STRING_STOP_DNS, strlen(MAGIC_STRING_STOP_DNS), 0, (struct sockaddr*)&addr, sizeof(addr));

    this->dnsState = DNS_SERVER_TERMINATING;

    print_level(NSLOGGER_LEVEL_INFO, "Magic string was sent to terminate DNS server: %s.\n", _localDNSIP );

    close(sockfd);

}

void DNSServer::stopDNSServer()
{
    const char *ipv4_dns_addr;

    if(this->localDNSIP == NULL || strcmp(this->localDNSIP, DEFAULT_MAGIC_IPV4_ADDR) == 0 )
        ipv4_dns_addr = DEFAULT_BIND_IP;
    else
        ipv4_dns_addr = this->localDNSIP;

    stopDNSServer(ipv4_dns_addr);
}

/* Returns a display name for the peer; currently inet_ntoa, so
   statically allocated */
const char * DNSServer::peer_display(struct peer_t *p)
{
    return inet_ntoa(p->tcp.sin_addr);
}


void DNSServer::peer_mark_as_dead(struct peer_t *p)
{
    close(p->tcp_fd);
    p->tcp_fd = -1;
    p->con = DEAD;
    print_level(NSLOGGER_LEVEL_DEBUG, "peer %s got disconnected\n", peer_display(p));
}

/* Return a positive positional number or -1 for unfound entries. */
int DNSServer::request_find(uint id)
{
    uint pos = id % MAX_REQUESTS;

    for (;;) {
        if (requests[pos].id == id) {
            print_level(NSLOGGER_LEVEL_DEBUG, "found id=%d at pos=%d\n", id, pos);
            return pos;
        }
        else {
            pos++;
            pos %= MAX_REQUESTS;
            if (pos == (id % MAX_REQUESTS)) {
                print_level(NSLOGGER_LEVEL_DEBUG, "can't find id=%d\n", id);
                return -1;
            }
        }
    }
}



/*
 *
 * Sockify connect
 * client >>>>>>  (Authentication Negotitation) >>>>> Socks Server
 * client <<<<<<  (Authentication Feedback)    <<<<< Socks Server
 * client >>>>>>  (Command request)            >>>>> Socks Server
 * client <<<<<<  (Request response)           <<<<< Socks Server
 *
 * --------------------------------------------------------------
 * client <><><><><><><> (data connection)     <><><> Socks Server
 *
 */

/* Returns a display name for the peer; currently inet_ntoa, so
   statically allocated */
const char * DNSServer::peer_socks5_display(struct peer_t *p)
{
    return inet_ntoa(p->socks5_tcp.sin_addr);
}

int DNSServer::peer_socks5_connect(struct peer_t *p, struct in_addr socks5_addr, struct in_addr ns_addr)
{
    int socket_opt_val = 1;
    int cs;

    if (p->con == SOCKS5_CONNECTING) {
        print_level(NSLOGGER_LEVEL_INFO, "It appears that peer %s is already CONNECTING to sock5 server.\n",
               peer_display(p));
        return 1;
    }


    if ((p->tcp_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        print_level(NSLOGGER_LEVEL_ERROR, "Can't create TCP socket\n");
        return 0;
    }

    if (setsockopt(p->tcp_fd, SOL_SOCKET, SO_REUSEADDR, &socket_opt_val, sizeof(int)))
        print_level(NSLOGGER_LEVEL_ERROR, "Setting SO_REUSEADDR failed\n");

    if (fcntl(p->tcp_fd, F_SETFL, O_NONBLOCK))
        print_level(NSLOGGER_LEVEL_ERROR, "Setting O_NONBLOCK failed\n");

    p->tcp.sin_family = AF_INET;

    // This should not be hardcoded to a magic number; per ns port data structure changes required
    p->tcp.sin_port = htons(53);

    p->tcp.sin_addr = ns_addr;

    p->socks5_tcp.sin_family = AF_INET;

    p->socks5_tcp.sin_addr = socks5_addr;

    p->socks5_tcp.sin_port = htons(remoteSocksPort);

    print_level(NSLOGGER_LEVEL_INFO, "connecting to Socks5 proxy %s on port %i\n", peer_socks5_display(p), ntohs(p->socks5_tcp.sin_port));

    cs = connect(p->tcp_fd, (struct sockaddr*)&p->socks5_tcp, sizeof(struct sockaddr_in));

    if (cs != 0 && errno != EINPROGRESS) {
        print_level(NSLOGGER_LEVEL_ERROR, "connect status: return code %d and errno %d.", cs, errno);
        return 0;
    }

    // We should be in non-blocking mode now
    p->bl = 0;
    p->con = SOCKS5_CONNECTING;

    return 1;

}

/* Returns 1 upon non-blocking connection; 0 upon serious error */
int DNSServer::peer_socks5_connected(struct peer_t *p)
{
    int cs;
     /* QUASIBUG This is not documented as a correct way to poll for
        connection establishment. Linux connect(2) says: “Generally,
        connection-based protocol sockets may successfully connect()
        only once...It is possible to select(2) or poll(2) for
        completion by selecting the socket for writing.  After
        select(2) indicates writability, use getsockopt(2) to read the
        SO_ERROR option at level SOL_SOCKET to determine whether
        connect() completed successfully (SO_ERROR is zero) or
        unsuccessfully (SO_ERROR is one of the usual error codes listed
        here, explaining the reason for the failure).”

        If this works the way it’s documented to work, we should just
        use the documented interface.
     */
/*
  Mac OS X
  Non-blocking connect
     When a TCP socket is set non-blocking, and the connection cannot be established immediately, connect(2)
     returns with the error EINPROGRESS, and the connection is established asynchronously.

     When the asynchronous connection completes successfully, select(2) or poll(2) or kqueue(2) will indi-cate indicate
     cate the file descriptor is ready for writing.  If the connection encounters an error, the file
     descriptor is marked ready for both reading and writing, and the pending error can be retrieved via the
     socket option SO_ERROR.

     Note that even if the socket is non-blocking, it is possible for the connection to be established imme-diately. immediately.
     diately. In that case connect(2) does not return with EINPROGRESS.
 */

    cs = connect(p->tcp_fd, (struct sockaddr*)&p->socks5_tcp, sizeof(struct sockaddr_in));

    if (cs == 0 || (cs == -1 && errno == EISCONN)) {
        return 1;
    } else {

        print_level(NSLOGGER_LEVEL_ERROR, "connect fail: return code %d and errno %d.", cs, errno);

        close(p->tcp_fd);
        p->tcp_fd = -1;
        p->con = DEAD;
        return 0;
    }
}

// assuming connection is established, send out authentication negotitation.

int DNSServer::peer_socks5_snd_auth_neg(struct peer_t *p)
{
    /*send socks5 non-authentication negotitation*/
    char socks5_neg_msg[]={0x5,0x1,0x0};

    int ret;

    ret = _nonblocking_send(p->tcp_fd, socks5_neg_msg, sizeof(socks5_neg_msg));

    if (ret == -1) {
        peer_mark_as_dead(p);
        print_level(NSLOGGER_LEVEL_ERROR, "Error in sending authentication ret:%d errno:%d\n", ret, errno);
        return 0;
    }
    p->con = SOCKS5_AUTH_WAIT;
    print_level(NSLOGGER_LEVEL_INFO, "Send authentication to socks5 server%d\n", ret);
    return 1;

}

// process authentication feedback

int DNSServer::peer_socks5_rcv_auth_process(struct peer_t *p)
{
    int ret;
    char buff[100];
    memset(buff,0,100);
    while ((ret = read(p->tcp_fd, buff, sizeof(buff))) < 0 && errno == EAGAIN);

    if(ret == 0){
        peer_mark_as_dead(p);
        return 0;
    }

    if(buff[0] != 0x5 || buff[1] != 0x0){
        print_level(NSLOGGER_LEVEL_ERROR, "Socks server return error authentication message: %s\n", buff);
        peer_mark_as_dead(p);
        return 0;
    }

    print_level(NSLOGGER_LEVEL_INFO, "Socks server authentication successfully.\n");

    return 1;
}

// send out command request

int DNSServer::peer_socks5_snd_cmd(struct peer_t *p)
{
    /*
     The SOCKS request is formed as follows:

        +----+-----+-------+------+----------+----------+
        |VER | CMD |  RSV  | ATYP | DST.ADDR | DST.PORT |
        +----+-----+-------+------+----------+----------+
        | 1  |  1  | X'00' |  1   | Variable |    2     |
        +----+-----+-------+------+----------+----------+

     Where:

          o  VER    protocol version: X'05'
          o  CMD
             o  CONNECT X'01'
             o  BIND X'02'
             o  UDP ASSOCIATE X'03'
          o  RSV    RESERVED
          o  ATYP   address type of following address
             o  IP V4 address: X'01'
             o  DOMAINNAME: X'03'
             o  IP V6 address: X'04'
          o  DST.ADDR       desired destination address
          o  DST.PORT desired destination port in network octet
             order
     */
    int ret;
    char buff[100];
    memset(buff,0,100);
    buff[0]=0x5; //ver
    buff[1]=0x1; //CMD
    buff[2]=0x0; //RSV
    buff[3]=0x1; //ATYP
    int byteLen = 4;

    in_addr_t addr = p->tcp.sin_addr.s_addr;

    memcpy(buff + byteLen, &(addr), sizeof(addr));
    byteLen += sizeof(addr);

    in_port_t port = p->tcp.sin_port;
    memcpy(buff + byteLen, &(port), sizeof(port));
    byteLen += sizeof(port);

    ret = _nonblocking_send(p->tcp_fd, buff, byteLen);

    if (ret == -1) {
        print_level(NSLOGGER_LEVEL_ERROR, "Error in sending connect command ret:%d errno:%d\n", ret, errno);
        peer_mark_as_dead(p);
        return 0;
    }

    p->con = SOCKS5_CMD_WAIT;
    print_level(NSLOGGER_LEVEL_INFO, "Send connect command to socks5 server%d\n", ret);
    return 1;

}

// process commnd response
int DNSServer::peer_socks5_rcv_cmd_process(struct peer_t *p)
{
    int ret;
    char buff[1024];
    memset(buff,0,1024);
    while ((ret = read(p->tcp_fd, buff, sizeof(buff))) < 0 && errno == EAGAIN);

    if(ret == 0){
        peer_mark_as_dead(p);
        return 0;
    }

    if(buff[0] != 0x5 || buff[1] != 0x0){
        print_level(NSLOGGER_LEVEL_ERROR, "Socks server connect error : %d\n", buff[1]);
        peer_mark_as_dead(p);
        return 0;
    }

    print_level(NSLOGGER_LEVEL_INFO, "Socks server connect successfully.\n");

    return 1;
}

/* Returns 1 upon non-blocking connection setup; 0 upon serious error */
int DNSServer::peer_connect(struct peer_t *p, struct in_addr ns)
{
    int socket_opt_val = 1;
    int cs;

    if (p->con == CONNECTING || p->con == CONNECTING2) {
        print_level(NSLOGGER_LEVEL_INFO, "It appears that peer %s is already CONNECTING\n",
               peer_display(p));
        return 1;
    }


    if ((p->tcp_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        print_level(NSLOGGER_LEVEL_ERROR, "Can't create TCP socket\n");
        return 0;
    }

    if (setsockopt(p->tcp_fd, SOL_SOCKET, SO_REUSEADDR, &socket_opt_val, sizeof(int)))
        print_level(NSLOGGER_LEVEL_ERROR, "Setting SO_REUSEADDR failed\n");

    if (fcntl(p->tcp_fd, F_SETFL, O_NONBLOCK))
        print_level(NSLOGGER_LEVEL_ERROR, "Setting O_NONBLOCK failed\n");

    p->tcp.sin_family = AF_INET;

    // This should not be hardcoded to a magic number; per ns port data structure changes required
    p->tcp.sin_port = htons(53);

    p->tcp.sin_addr = ns;

    print_level(NSLOGGER_LEVEL_INFO, "connecting to %s on port %i\n", peer_display(p), ntohs(p->tcp.sin_port));
    cs = connect(p->tcp_fd, (struct sockaddr*)&p->tcp, sizeof(struct sockaddr_in));

    if (cs != 0 && errno != EINPROGRESS) {
        print_level(NSLOGGER_LEVEL_ERROR, "connect status: return code %d and errno %d.", cs, errno);
        return 0;
    }

    // We should be in non-blocking mode now
    p->bl = 0;
    p->con = CONNECTING;

    return 1;
}

//TODO: test incorrect DNS address.
/* Returns 1 upon non-blocking connection; 0 upon serious error */
int DNSServer::peer_connected(struct peer_t *p)
{

    int error = 0;
    socklen_t len;

    if (getsockopt(p->tcp_fd, SOL_SOCKET, SO_ERROR, &error, &len) < 0) {

        print_level(NSLOGGER_LEVEL_ERROR, "connect fail: return error code %d and errno (%d).", error, errno);
        close(p->tcp_fd);
        p->tcp_fd = -1;
        p->con = DEAD;
        return 0;

    }else{

        print_level(NSLOGGER_LEVEL_INFO, "Remote DNS %s is connected.\n", this->remoteDNSIP);
        p->con = CONNECTED;
        return 1;

    }
}

/* Returns 1 upon sent request; 0 upon serious error and 2 upon disconnect */
int DNSServer::peer_sendreq(struct peer_t *p, struct request_t *r)
{

    print_level(NSLOGGER_LEVEL_DEBUG, "Sending request ID %d to remote TCP DNS server.\n", r->id);

    int rc;
    if((rc = _nonblocking_send(p->tcp_fd, r->b, r->bl + 2)) == -1){
        print_level(NSLOGGER_LEVEL_ERROR, "Errno (%d): Failed to send DNS request to remote DNS\n", errno);
        peer_mark_as_dead(p);
        return 2;
    }

    print_level(NSLOGGER_LEVEL_DEBUG, "DNS request ID %d was sent to remote TCP DNS server.\n", r->id);
    r->active = SENT;
    print_level(NSLOGGER_LEVEL_DEBUG, "peer_sendreq write attempt returned\n");
    return 1;
}

/* Returns -1 on error, returns 1 on something, returns 2 on something, returns 3 on disconnect. */
/* XXX This function needs a really serious re-write/audit/etc. */
int DNSServer::peer_readres(struct peer_t *p)
{
    struct request_t *r;
    int ret;
    unsigned short int *ul;
    int req_id;
    int req;
    unsigned short int *l;
    int len;

    l = (unsigned short int*)p->b;

     /* BUG: we’re reading on a TCP socket here, so we could in theory
        get a partial response. Using TCP puts the onus on the user
        program (i.e. this code) to buffer bytes until we have a
        parseable response. This probably won’t happen very often in
        practice because even with DF, the path MTU is unlikely to be
        smaller than the DNS response. But it could happen.  And then
        we fall into the `processanswer` code below without having the
        whole answer. */
    /* This is reading data from Tor over TCP */
    while ((ret = read(p->tcp_fd, (p->b + p->bl), (RECV_BUF_SIZE - p->bl))) < 0 && errno == EAGAIN);

    if (ret == 0) {
        print_level(NSLOGGER_LEVEL_INFO, "Nothing can be read from remote DNS.\n");
        peer_mark_as_dead(p);
        return 3;
    }

    p->bl += ret;

    // get answer from receive buffer
    do {

        if (p->bl < 2) {
            return 2;
        }
        else {
            len = ntohs(*l);

            print_level(NSLOGGER_LEVEL_DEBUG, "r l=%d r=%d\n", len, p->bl-2);

            if ((len + 2) > p->bl)
                return 2;
        }

        ul = (unsigned short int*)(p->b + 2);
        req_id = ntohs(*ul);

        print_level(NSLOGGER_LEVEL_DEBUG, "received answer %d bytes with remote request ID (%d)\n", p->bl, req_id);

        if ((req = request_find(req_id)) == -1) {
            memmove(p->b, (p->b + len + 2), (p->bl - len - 2));
            p->bl -= len + 2;
            return 0;
        }
        r = &requests[req];

        // write back real req_id
        *ul = htons(r->rid);

        // Remove the AD flag from the reply if it has one. Because we might be
        // answering requests to 127.0.0.1, the client might consider us
        // trusted. While trusted, we shouldn't indicate that data is DNSSEC
        // valid when we haven't checked it.
        // See http://tools.ietf.org/html/rfc2535#section-6.1
        if (len >= 6)
          p->b[5] &= 0xdf;

        /* This is where we send the answer over UDP to the client */
        r->a.sin_family = AF_INET;
        while (sendto(udp_fd, (p->b + 2), len, 0, (struct sockaddr*)&r->a, sizeof(struct sockaddr_in)) < 0 && errno == EAGAIN);

        print_level(NSLOGGER_LEVEL_DEBUG, "forwarding answer (%d bytes) with DNS request ID (%d)\n", len, *ul);

        memmove(p->b, p->b + len +2, p->bl - len - 2);
        p->bl -= len + 2;

        // mark as handled/unused
        r->id = 0;

    } while (p->bl > 0);

    return 1;
}

/* Handles outstanding peer requests and does not return anything. */
void DNSServer::peer_handleoutstanding(struct peer_t *p)
{
    int i;
    int ret;

    /* QUASIBUG It doesn’t make sense that sometimes `request_add`
        will queue up a request to be sent to nameserver #2 when a
        connection is already open to nameserver #1, but then send that
        request to nameserver #3 if nameserver #3 happens to finish
        opening its connection before nameserver #2. */

    for (i = 0; i < MAX_REQUESTS; i++) {
        struct request_t *r = &requests[i];
        if (r->id != 0 && r->active == WAITING) {
            ret = peer_sendreq(p, r);
            print_level(NSLOGGER_LEVEL_DEBUG, "peer_sendreq returned %d\n", ret);
        }
    }
}

/* Currently, we only return the 0th peer. Someday we might want more? */
/* REFACTOR if we aren't going to round-robin among the peers, we
   should remove all the complexity having to do with having more than
   one peer. */
struct peer_t * DNSServer::peer_select(void)
{
    return &peers[0];
}

struct in_addr DNSServer::socks5_proxy_select(void)
{
    struct in_addr socks5_proxy;

    unsigned long int ns;

    if(inet_pton(AF_INET, remoteSocksIP, &ns)){

        socks5_proxy.s_addr = ns;

        return socks5_proxy;
    }else{

        print_level(NSLOGGER_LEVEL_ERROR, "%s: is not a valid IPv4 address\n", remoteSocksIP);

        socks5_proxy.s_addr = 0;

        return socks5_proxy;
    }
}

/* Selects a random nameserver from the pool and returns the number. */
struct in_addr DNSServer::ns_select(void)
{
    // This could use a real bit of randomness, I suspect
    return nameservers;
}

/* Return 0 for a request that is pending or if all slots are full, otherwise
   return the value of peer_sendreq or peer_connect respectively... */
int DNSServer::request_add(struct request_t *r)
{
    uint pos = r->id % MAX_REQUESTS; // XXX r->id is unchecked
    struct peer_t *dst_peer;
    unsigned short int *ul;
    time_t ct = time(NULL);
    struct request_t *req_in_table = 0;

    print_level(NSLOGGER_LEVEL_DEBUG, "adding new request (id=%d)\n", r->id);
    for (;;) {
        if (requests[pos].id == 0) {
            // this one is unused, take it
            print_level(NSLOGGER_LEVEL_DEBUG, "new request added at pos: %d\n", pos);
            req_in_table = &requests[pos];
            break;
        }
        else {
            if (requests[pos].id == r->id) {
                if (memcmp((char*)&r->a, (char*)&requests[pos].a, sizeof(r->a)) == 0) {
                    print_level(NSLOGGER_LEVEL_DEBUG, "For DNS request with ID %d, hash position %d is already taken by request with the same ID. Drop this request.\n", r->id, pos);
                    delete r;
                    return 0;
                }
                else {
                    print_level(NSLOGGER_LEVEL_DEBUG, "Hash position %d selected\n", pos);
                     /* REFACTOR If it’s okay to do this, it would be
                        simpler to always do it, instead of only on
                        collisions. Then, if it’s buggy, it’ll show up
                        consistently in testing. */
                    do {
                        r->id = ((rand()>>16) % 0xffff);
                    } while (r->id < 1);
                    pos = r->id % MAX_REQUESTS;
                    print_level(NSLOGGER_LEVEL_DEBUG, "NATing id (id was %d now is %d)\n", r->rid, r->id);
                    continue;
                }
            }
            else if ((requests[pos].timeout + remoteDNSTimeout) > ct) {
                // request timed out, take it
                print_level(NSLOGGER_LEVEL_DEBUG, "Taking pos from timed out request.\n");
                req_in_table = &requests[pos];
                break;
            }
            else {
                pos++;
                pos %= MAX_REQUESTS;
                if (pos == (r->id % MAX_REQUESTS)) {
                    print_level(NSLOGGER_LEVEL_ERROR, "no more free request slots, wow this is a busy node. dropping request!\n");
                    delete r;
                    return 0;
                }
            }
        }
    }
    print_level(NSLOGGER_LEVEL_DEBUG, "using request slot %d\n", pos); /* REFACTOR: move into loop */

    r->timeout = time(NULL); /* REFACTOR not ct? sloppy */

    // update id
    ul = (unsigned short int*)(r->b + 2);
    *ul = htons(r->id);
    print_level(NSLOGGER_LEVEL_DEBUG, "updating id: %d\n", htons(r->id));

    if ( req_in_table == NULL ) {
        return -1;
    } else {
        memcpy((char*)req_in_table, (char*)r, sizeof(*req_in_table));
        delete r;
    }

    // XXX: nice feature to have: send request to multiple peers for speedup and reliability
    print_level(NSLOGGER_LEVEL_DEBUG, "selecting peer\n");
    dst_peer = peer_select();
    print_level(NSLOGGER_LEVEL_DEBUG, "peer selected: %d\n", dst_peer->tcp_fd);

    if (dst_peer->con == CONNECTED) {

        return peer_sendreq(dst_peer, req_in_table);
    }
    else {
        // The request will be sent by peer_handleoutstanding when the
        // connection is established. Actually (see QUASIBUG notice
        // earlier) when *any* connection is established.
        if(isSockify)

            return peer_socks5_connect(dst_peer,socks5_proxy_select(),ns_select());

        else

            return peer_connect(dst_peer, ns_select());
    }
}

void DNSServer::process_incoming_request(struct request_t *tmp)
{
    // get request id
    unsigned short int *ul = (unsigned short int*) (tmp->b + 2);
    tmp->rid = tmp->id = ntohs(*ul);
    // get request length
    ul = (unsigned short int*)tmp->b;
    *ul = htons(tmp->bl);

    print_level(NSLOGGER_LEVEL_DEBUG, "received request of %d bytes, id = %d\n", tmp->bl, tmp->id);

    request_add(tmp); // This should be checked; we're currently ignoring important returns.
}

void DNSServer::_stop_server()
{
    //close binded UDP socket
    close(udp_fd);

    for(int i=0; i<MAX_PEERS; i++){
        if(peers[i].tcp_fd > 0 && peers[i].con != DEAD )
            close(peers[i].tcp_fd);
    }
    print_level(NSLOGGER_LEVEL_INFO, "DNS server is terminated.\n");

    this->dnsState = DNS_SERVER_TERMINATED;

}

int DNSServer::_start_server()
{
    struct sockaddr_in udp;
    struct pollfd pfd[MAX_PEERS+1];
    int poll2peers[MAX_PEERS];
    int fr;
    int i;
    int pfd_num;
    int socket_opt_val;

    this->dnsState = DNS_SERVER_STARTED;

    for (i = 0; i < MAX_PEERS; i++) {
        peers[i].tcp_fd = -1;
        poll2peers[i] = -1;
        peers[i].con = DEAD;
    }
    memset((char*)requests, 0, sizeof(requests)); // Why not bzero?

    if ((udp_fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        print_level(NSLOGGER_LEVEL_ERROR, "can't create UDP socket\n");
        return(-1);
    }

    if (setsockopt(udp_fd, SOL_SOCKET, SO_REUSEADDR, &socket_opt_val, sizeof(int)) < 0) {
        print_level(NSLOGGER_LEVEL_ERROR, "setsockopt failed. Errno (%d)\n", errno);
        return (-1);
    }

    memset((char*)&udp, 0, sizeof(struct sockaddr_in)); // bzero love
    udp.sin_family = AF_INET;
    udp.sin_port = htons(localDNSPort);
    
    if(strcmp(localDNSIP, DEFAULT_MAGIC_IPV4_ADDR) == 0){

        print_level(NSLOGGER_LEVEL_DEBUG, "UDP bind address assigned to INADDR_ANY\n");

        udp.sin_addr.s_addr = htonl(INADDR_ANY);
    
    }else{
        
        if (!inet_aton(localDNSIP, (struct in_addr*)&udp.sin_addr)) {
            print_level(NSLOGGER_LEVEL_ERROR, "%s is not a valid IPv4 address.\n", localDNSIP);
            return(0); // Why is this 0?
        }
        
    }

    if (bind(udp_fd, (struct sockaddr*)&udp, sizeof(struct sockaddr_in)) < 0) {
        print_level(NSLOGGER_LEVEL_ERROR, "Errno (%d). Failed to bind to %s:%d\n", errno, localDNSIP, localDNSPort);
        close(udp_fd);
        return(-1); // Perhaps this should be more useful?
    }


    for (;;) {
        // populate poll array
        for (pfd_num = 1, i = 0; i < MAX_PEERS; i++) {
            if (peers[i].tcp_fd != -1) {
                pfd[pfd_num].fd = peers[i].tcp_fd;
                switch (peers[i].con) {
                case CONNECTED:
                    pfd[pfd_num].events = POLLIN|POLLPRI;
                    break;
                case DEAD:
                    pfd[pfd_num].events = POLLOUT|POLLERR;
                    break;
                case CONNECTING:
                    pfd[pfd_num].events = POLLOUT|POLLERR;
                    break;
                case CONNECTING2:
                    pfd[pfd_num].events = POLLOUT|POLLERR;
                    break;
                case SOCKS5_CONNECTING:
                     pfd[pfd_num].events = POLLOUT|POLLERR;
                    break;
                case SOCKS5_AUTH_WAIT:
                    pfd[pfd_num].events = POLLIN | POLLPRI;
                case SOCKS5_CMD_WAIT:
                    pfd[pfd_num].events = POLLIN | POLLPRI;
                default:
                    pfd[pfd_num].events = POLLOUT|POLLERR;
                    break;
                }
                poll2peers[pfd_num-1] = i;
                pfd_num++;
            }
        }

        pfd[0].fd = udp_fd;
        pfd[0].events = POLLIN|POLLPRI;

        //print_level(NSLOGGER_LEVEL_DEBUG, "Watching %d file descriptors\n", pfd_num);

        fr = poll(pfd, pfd_num, -1);

        //print_level(NSLOGGER_LEVEL_DEBUG, "Total number of (%d) file descriptors became ready\n", fr);

        // handle tcp connections
        for (i = 1; i < pfd_num; i++) {
            if (pfd[i].fd != -1 && ((pfd[i].revents & POLLIN) == POLLIN ||
                    (pfd[i].revents & POLLPRI) == POLLPRI || (pfd[i].revents & POLLOUT)
                    == POLLOUT || (pfd[i].revents & POLLERR) == POLLERR)) {
                
                print_level(NSLOGGER_LEVEL_DEBUG, "TCP connection poll event.\n");
                
                uint peer = poll2peers[i-1];
                struct peer_t *p = &peers[peer];

                if (peer > MAX_PEERS) {
                    print_level(NSLOGGER_LEVEL_ERROR, "Something is wrong! poll2peers[%i] is larger than MAX_PEERS: %i\n", i-1, peer);
                } else switch (p->con) {
                case CONNECTED:
                    //read DNS from TCP port only if data is available
                    peer_readres(p);
                    break;
                case CONNECTING:
                case CONNECTING2:
                    if (peer_connected(p)) {
                        peer_handleoutstanding(p);
                    }
                    break;
                case SOCKS5_CONNECTING:
                    if(peer_socks5_connected(p)){
                        peer_socks5_snd_auth_neg(p);
                    }
                    break;
                case SOCKS5_AUTH_WAIT:
                    if(peer_socks5_rcv_auth_process(p)){
                        peer_socks5_snd_cmd(p);
                    }
                    break;
                case SOCKS5_CMD_WAIT:
                    if(peer_socks5_rcv_cmd_process(p)){
                        p->con = CONNECTED;
                        peer_handleoutstanding(p);
                    }
                case DEAD:
                default:
                    print_level(NSLOGGER_LEVEL_ERROR, "peer %s in bad state %i\n", peer_display(p), p->con);
                    break;
                }
            }
        }

        // handle port 53
        if ((pfd[0].revents & POLLIN) == POLLIN || (pfd[0].revents & POLLPRI) == POLLPRI) {
            struct request_t * dns_request = new request_t;
            memset((char*)dns_request, 0, sizeof(struct request_t)); // bzero
            dns_request->al = sizeof(struct sockaddr_in);

            dns_request->bl = recvfrom(udp_fd, dns_request->b+2, RECV_BUF_SIZE-2, 0,
                              (struct sockaddr*)&(dns_request->a), &(dns_request->al));
            
            print_level(NSLOGGER_LEVEL_DEBUG, "DNS UDP connection poll event.\n");
            
            if (dns_request->bl < 0) {
                print_level(NSLOGGER_LEVEL_ERROR, "recvfrom on UDP fd with negative size");
            } else {
                if(memcmp((char*)dns_request->b+2, (char*)MAGIC_STRING_STOP_DNS,strlen(MAGIC_STRING_STOP_DNS)) == 0){
                    _stop_server();
                    delete dns_request;
                    return 0;
                }else{
                    print_level(NSLOGGER_LEVEL_INFO, "Receive DNS request from UDP port.\n");
                    process_incoming_request(dns_request);
                }
            }
        }
    }//end for(;;)
}

int DNSServer::_nonblocking_send(int fd, void* buff, int len)
{
    int nByteWritten = 0;
    int nByteToWrite = len;
    unsigned char* topPtr =(unsigned char*) buff;
    int retry_count = 0;

    print_level(NSLOGGER_LEVEL_DEBUG, "Send: %d of byte to write, %d of byte written\n", nByteToWrite, nByteWritten);

    while(nByteToWrite > 0){

        nByteWritten = write(fd, topPtr, nByteToWrite);

        if(nByteWritten <0){

            if((errno == EINTR || errno == EWOULDBLOCK)
                    && retry_count < MAX_TCP_WRITE_TIME){
                retry_count++;
                nByteWritten = 0;
            }else
                return -1;

        }else{
            retry_count = 0;
            topPtr += nByteWritten;
            nByteToWrite -= nByteWritten;
            print_level(NSLOGGER_LEVEL_DEBUG, "Send: %d of byte to write, %d of byte written\n", nByteToWrite, nByteWritten);

        }

    }

    return len;

}
