#!perl -w
# $Id: paint.pl,v 1.3 2004/07/21 17:47:38 szabgab Exp $
# Draw triangles in MS Paint.


use strict;

use Win32::GuiTest qw(:ALL); 

system("start /max mspaint");
sleep 2;
my @windows = FindWindowLike(0, "Paint", "");
die "Could not find Paint\n" if not @windows;


SetForegroundWindow($windows[0]);
sleep 1;

# totaly guess work about the location of the area where one can draw.
# A better guess would be welcome
MouseMoveAbsPix((GetWindowRect($windows[0]))[0,1]);
SendMouse ( "{REL50,50}" );  

# Using high-level functions
SendMouse ( "{LEFTDOWN}" );
for (1..100) { SendMouse ( "{REL1,1}"  ); }
for (1..100) { SendMouse ( "{REL1,-1}" ); }
for (1..200) { SendMouse ( "{REL-1,0}" ); }
SendMouse ( "{LEFTUP}" );



# Using low level functions
SendMouseMoveRel(5,20);
SendLButtonDown();
for (1..100) { SendMouseMoveRel(1,1);  }
for (1..100) { SendMouseMoveRel(1,-1); }
for (1..200) { SendMouseMoveRel(-1,0); }
SendLButtonUp();


