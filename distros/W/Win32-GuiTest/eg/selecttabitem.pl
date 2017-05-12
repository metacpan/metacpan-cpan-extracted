#!/usr/bin/perl
# $Id: selecttabitem.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
#

use Win32::GuiTest qw(GetWindowID GetChildWindows GetWindowText
    GetForegroundWindow PostMessage PushButton SendKeys SelectTabItem);

use Win32::GuiTest::Cmd qw(System);

# Test 

# Open System Properties
# Tested on Win2k an NT4
System();
#system("start RunDLL32.exe shell32,Control_RunDLL sysdm.cpl,\@0,2");
sleep(2);
# Select various items on tab control
# Using Window ID
SelectTabItem(12320, 0);
sleep(1);
SelectTabItem(12320, 2);
sleep(1);
SelectTabItem(12320, 1);
sleep(1);
#PushButton("^Cancel");
SendKeys("{ESC}");
