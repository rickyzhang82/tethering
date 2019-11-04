This app runs a SOCKS5 proxy server (with DNS) on your iOS device (iPhone, iPad). This allows you to tether to your phone as a hotspot, and bypass carrier restrictions.

&nbsp; 


## Installing
You will need a Mac running Xcode.  

Open the `Tethering.xcodeproj` file in Xcode and make the following changes:  

 - In the Projects/Targets menu, set the `Bundle Identifer` to something unique. 
 - In the 'Signing and Capabilities' menu, set the `Team` to your Apple ID/account.
 - Connect your device and hit the Build/Run button to install the app

&nbsp;


## Running

1. On your computer setup an Adhoc wifi network
2. Connect your iPhone/iPad to this Adhoc network
3. Launch the tethering app on your mobile device
4. Hit `Start` in the app 
5. Configure your browser/application to use the SOCKS IP address and port as listed in the app. Use the `proxy DNS when using SOCKS` option

You should now be able to connect to the internet!  

You can also use the automatic proxy URL when available: `http://your-iphone-name.local:8080/socks.pac`  

&nbsp;

## Notes

Apple require you to reinstall the apps in development every 2 weeks - just build/run the app again via Xcode to refresh.



## Original readme

This iOS App was forked from [an abandoned project](https://code.google.com/p/iphone-socks-proxy/). The current goal is to make this iOS App great again. Please read [my user guide](https://github.com/rickyzhang82/tethering/wiki).

If you like this App, please visit [UNICEF tap project website](http://tap.unicefusa.org/) and make a donation to the kids who are in desperate need of clean water supply.

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
