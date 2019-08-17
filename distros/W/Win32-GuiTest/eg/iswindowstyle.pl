#!/usr/bin/perl
# $Id: iswindowstyle.pl,v 1.3 2004/03/21 08:21:28 ctrondlp Exp $
#

use Win32::GuiTest qw(:FUNC :LVS);

# Test IsWindowStyle()

# Get handle to desktop listview.  Note: Tested on Win2k and NT4.
my ($pm) = FindWindowLike(GetDesktopWindow(), "", "Progman");
my ($sdv) = FindWindowLike($pm, "", "SHELLDLL_DefView");
my ($dlv) = FindWindowLike($sdv, "", "SysListView32");
# Check to see if desktop icons are marked for auto-arrange.
if (IsWindowStyle($dlv, LVS_AUTOARRANGE)) {
    print "Desktop icons are set to auto-arranged.\n";
} else {
    print "Desktop icons are NOT set to auto-arranged.\n";
    ## Code to auto-arrange desktop icons (MouseClick,SendKeys) ##
}


