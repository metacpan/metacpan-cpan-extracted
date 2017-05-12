#!/usr/bin/perl
# $Id: rawkey.pl,v 1.3 2004/03/21 08:21:28 ctrondlp Exp $
#

use Win32::GuiTest qw(:FUNC :VK);

while (1) {
    SendRawKey(VK_DOWN, KEYEVENTF_EXTENDEDKEY); 
    SendKeys "{PAUSE 200}";
}
