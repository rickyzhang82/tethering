This iOS App was forked from [an abandoned project](https://code.google.com/p/iphone-socks-proxy/). The current goal is to make this iOS App great again. Please read [my user guide](https://github.com/rickyzhang82/tethering/wiki).

If you like this App, please visit [American Red Cross website](https://www.redcross.org/) and make a donation to your local Red Cross chapter.

Thanks for your support.

Ricky

Change log

---
Release V1.7
* Add unlimited background. Feel free to close screen to save battery. Thanks @bsuh for his patch.
* Finally, we have a pull request to change ugly UI to a new modern look. Thanks @rickybloomfield for his patch.

Release V1.6
* Fix problem when remote network is faster than local network. Thanks @optimoid and @bsuh for their patch and bug report.
* Refactor socks proxy message debug log.

Release V1.5
* Refactor DNS message log
* Verify compatible with iOS 9.3

Release V1.4
* Support iPad tethering. Add http server to host socks.pac file
* Fix several memory leak issues.

Release V1.3
* Update NSLogger API compatible with iOS 8

Release V1.2
* Convert xib to storyboard
* Fix Failed to compile: ttdnsd_platform.h not found error

Release V1.1
* Fix retrieve wifi IP address bug.
* Replace naive logging with NSLogger logging API
* Enable ARC and use modern Objective-C literal

Release v1.0.
* Support DNS server and Socks5 proxy server.
* Fix crash problem when wifi is not connected.
* Listenning socket reuse address and port if previous TCP connection in TIME_WAIT state.
---
