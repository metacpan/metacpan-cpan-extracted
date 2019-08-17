#!/usr/bin/perl
# $Id: showmouse.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
# This script has been written by Jarek Jurasz jurasz@imb.uni-karlsruhe.de

use Win32::GuiTest qw(GetCursorPos);

while (1)
{
  ($x, $y) = GetCursorPos();
  print "\rx:$x  y:$y   ";
  sleep 1;
}

