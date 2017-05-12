#!/usr/bin/perl
# $Id: start.pl,v 1.1 2004/07/13 21:52:26 szabgab Exp $

# Disclaimer: I tried this on my WindowsXP,
# Other Windows, or other configurations might place the "Run" option
# of the "Start" menu in different place so before running this script
# make sure that your version of Windows will bring you to the "Run" option
# if you press the left windows key and then the Up key 3 times.

# Written by Gabor Szabo <gabor@pti.co.il>

use Win32::GuiTest;

# open the Start menu by pressing the Left Windows Key 
# and then close it by hitting ESC.
Win32::GuiTest::SendKeys("{LWI}");
sleep 2;
Win32::GuiTest::SendKeys("{ESC}");

# Check out the version of your perl by opening a cmd.exe and typing perl -v
# the sleep 1; lines were added only so the viewer can observe the process
# you could actually send all the keys in one SendKeys call.

Win32::GuiTest::SendKeys("{LWI}");
sleep 1;
Win32::GuiTest::SendKeys("{UP}");
sleep 1;
Win32::GuiTest::SendKeys("{UP}");
sleep 1;
Win32::GuiTest::SendKeys("{UP}");
sleep 1;
Win32::GuiTest::SendKeys("{ENTER}");
sleep 1;
Win32::GuiTest::SendKeys("cmd{ENTER}");
sleep 1;
Win32::GuiTest::SendKeys("perl -v");
sleep 1;
Win32::GuiTest::SendKeys("{ENTER}");
sleep 1;
Win32::GuiTest::SendKeys("exit");
sleep 1;
Win32::GuiTest::SendKeys("{ENTER}");


