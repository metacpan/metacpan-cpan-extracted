use Win32::WebBrowser;

open_browser('http://www.google.com')
	or die $@;
