#!/usr/bin/perl
# $Id: notepad.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
#

use Win32::GuiTest;

system("start notepad.exe");
sleep 3;
Win32::GuiTest::SendKeys("If you're reading this inside notepad,\n");
Win32::GuiTest::SendKeys("we might consider this test succesful.\n");
Win32::GuiTest::SendKeys("Now I'll send notepad an ALT{+}F4 to close\n");
Win32::GuiTest::SendKeys("it. Please wait.......");
sleep 1;
Win32::GuiTest::SendKeys(".");
sleep 1;
Win32::GuiTest::SendKeys(".");
sleep 1;
Win32::GuiTest::SendKeys(".");
Win32::GuiTest::SendKeys("%{F4}{TAB}{ENTER}");
