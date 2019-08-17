#!/usr/bin/perl
# $Id: showcpl.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
# Shows how to open control panel apps programmatically
#

use Win32::GuiTest::Cmd qw(
    Accessibility AppWizard Console DateTime
    Display Exchange Internet Joystick Modem
    Mouse Multimedia Network Odbc Pcmcia Ports Ras
    Regional Server System Telephony Ups Users);

use Win32::GuiTest qw(SendKeys);

Modem(); sleep 1;
SendKeys("%{F4}");
Network();sleep 1;
SendKeys("%{F4}"); 
Console();sleep 1;
SendKeys("%{F4}"); 
Accessibility();sleep 1;
SendKeys("%{F4}"); 
AppWizard();   sleep 1;
SendKeys("%{F4}"); 
Pcmcia();     sleep 1;
SendKeys("%{F4}"); 
Regional(); sleep 1;
SendKeys("%{F4}"); 
Joystick(); sleep 1;
SendKeys("%{F4}"); 
Mouse(); sleep 1;
SendKeys("%{F4}"); 
Multimedia(); sleep 1;
SendKeys("%{F4}"); 
Odbc(); sleep 1;
SendKeys("%{F4}"); 
Ports(); sleep 1;
SendKeys("%{F4}"); 
Server(); sleep 1;
SendKeys("%{F4}"); 
System(); sleep 1;
SendKeys("%{F4}"); 
Telephony();sleep 1;
SendKeys("%{F4}"); 
DateTime();sleep 1;
SendKeys("%{F4}"); 
Ups();sleep 1;
SendKeys("%{F4}"); 
Internet(); sleep 1;
SendKeys("%{F4}"); 
Display(); sleep 1;
SendKeys("%{F4}"); 
Ras(); sleep 1;
SendKeys("%{F4}"); 
Users(); sleep 1;
SendKeys("%{F4}"); 
