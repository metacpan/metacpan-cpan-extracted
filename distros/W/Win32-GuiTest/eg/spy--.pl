#!/usr/bin/perl
# $Id: spy--.pl,v 1.3 2004/03/21 08:21:28 ctrondlp Exp $
# MS has a very nice tool (Spy++).
# This is Spy--
#

use Win32::GuiTest qw(FindWindowLike GetWindowText GetClassName
    GetChildDepth GetDesktopWindow);

for (FindWindowLike()) {
    $s = sprintf("0x%08X", $_ );
    $s .= ", '" .  GetWindowText($_) . "', " . GetClassName($_);
    print "+" x GetChildDepth(GetDesktopWindow(), $_), $s, "\n";
}
