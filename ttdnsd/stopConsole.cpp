
#include "ttdnsd.h"

int main(int argc, char** argv)
{
    DNSServer* dns_srv = DNSServer::getInstance();
    if(argc == 2)
        dns_srv->stopDNSServer(argv[1]);
    else
        dns_srv->stopDNSServer();
    return 0;
}
