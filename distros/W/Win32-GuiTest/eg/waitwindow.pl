#!/usr/bin/perl
# $Id: waitwindow.pl,v 1.3 2004/03/21 08:21:28 ctrondlp Exp $
# Slightly modified from version submitted by anonymous contributor.
#

use strict;
use Win32::GuiTest qw(IsWindow FindWindowLike SendKeys
	PushButton WaitWindow); 


# Test WaitWindow()

# en i18n constants 
sub SOL  { "^Solitaire" }
sub GAME { "%G" }
sub OPT  { "O" }
sub OPTIONS { "^Options" }
sub CANCEL  { "Cancel" }

# es i18n constants 
#sub SOL  { "^Solitario" }
#sub GAME { "%J" }
#sub OPT  { "O" }
#sub OPTIONS { "^Opciones" }
#sub CANCEL  { "Cancelar" }

# Open program
system("start sol.exe");
# Wait for program window to appear.
die "Couldn't open solitaire program!\n"
    unless WaitWindow(SOL);
# Select game menu
SendKeys(GAME);
# Open options menu
SendKeys(OPT); 
# Wait for options menu to appear for up to 5 seconds.
WaitWindow(OPTIONS, 5);
# Close options menu
PushButton(CANCEL);
# Close program
SendKeys("%{F4}"); 

