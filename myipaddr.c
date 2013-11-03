/*
 */

#include "myipaddr.h"


#include <stdio.h>
#include <stdlib.h>
#include <ifaddrs.h>
#include <string.h>
#include <stdbool.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <arpa/inet.h>
#include <ifaddrs.h>

#if ! defined(IFT_ETHER)
#define IFT_ETHER 0x6/* Ethernet CSMACD */
#endif

char * myipaddr(void)
{
	bool success;
	struct ifaddrs *addrs;
	const struct ifaddrs *cursor;
	const struct sockaddr_dl *dlAddr;
	const uint8_t *base;
	const struct ifaddrs * en0cursor=NULL;
	
	success = getifaddrs(&addrs) == 0;
	if (success) {
		cursor = addrs;
		while (cursor != NULL) {
			if ((cursor->ifa_flags & IFF_LOOPBACK) == 0 ) {
#ifdef DEBUG
				printf("%s ", (char *)cursor->ifa_name);
				printf("%s\n",inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr));
#endif
				if(!strcmp((char*)cursor->ifa_name,"en0"))
					en0cursor=cursor;
			}
			if ( (cursor->ifa_addr->sa_family == AF_LINK)
				&& (((const struct sockaddr_dl *) cursor->ifa_addr)->sdl_type ==IFT_ETHER)
				) {
				dlAddr = (const struct sockaddr_dl *) cursor->ifa_addr;
				//      fprintf(stderr, " sdl_nlen = %d\n", dlAddr->sdl_nlen);
				//      fprintf(stderr, " sdl_alen = %d\n", dlAddr->sdl_alen);
				base = (const uint8_t *) &dlAddr->sdl_data[dlAddr->sdl_nlen];
#ifdef DEBUG
				{
					int i;
					printf(" MAC address ");
					for (i = 0; i < dlAddr->sdl_alen; i++) {
						if (i != 0) {
							printf(":");
						}
						printf("%02x", base[i]);
					} 
					printf("\n");
				}
#endif
			}
			cursor = cursor->ifa_next;
		}
	}
	if(addrs)
		freeifaddrs(addrs);
	if(en0cursor!=NULL) {
		char *s = inet_ntoa(((struct sockaddr_in *)en0cursor->ifa_addr)->sin_addr);
		if (strcmp(s,"6.3.6.0"))
			return s;
	}
	return "no WiFi";
}
