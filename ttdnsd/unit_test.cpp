#include "ttdnsd.h"

int main()
{
    DNSServer* dns_srv = new DNSServer();
    dns_srv->startDNSServer();
    return 0;
}
