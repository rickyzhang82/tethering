This iOS App was forked from [an abandoned project](https://code.google.com/p/iphone-socks-proxy/). The current goal is to make this iOS App great again. Please read [my user guide](https://github.com/rickyzhang82/tethering/wiki).

Protecting the World against the tyranny
========================================

Please consider making your donation to the National Bank of Ukraine. The fundraiser [National Bank of Ukraine or NBU](https://en.wikipedia.org/wiki/National_Bank_of_Ukraine) is the central bank of Ukraine. You could help freedom fighters and Ukrainian civilians in humanitarian crisis:

- [Funds for Ukraine’s Armed Forces](https://bank.gov.ua/en/news/all/natsionalniy-bank-vidkriv-spetsrahunok-dlya-zboru-koshtiv-na-potrebi-armiyi)
- [Funds for Humanitarian Assistance to Ukrainians Affected by Russia’s Aggression](https://bank.gov.ua/en/news/all/natsionalniy-bank-vidkriv-rahunok-dlya-gumanitarnoyi-dopomogi-ukrayintsyam-postrajdalim-vid-rosiyskoyi-agresiyi)

If you are against funding bombs and arms, you could also donate to [Come Back Alive Charity](https://www.comebackalive.in.ua) which helps the Ukrainian armed forces with defense including medical assistance and rehabilitation. The organization is transparent with the donation and its spending.

- [Come Back Alive Charity](https://www.comebackalive.in.ua/donate)

Thank you for your support.

Ricky

Change log

----

Release V1.8
* Added a request to access local wifi network. Please enable it in your privacy setting.
* Added infos of Bonjour services for socks5, http PAC files, NSLogger.

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
