#!/usr/bin/perl
#----------------------------------------------------------------------#
# X11::GUITest ($Id: WebBrowser_1.pl 206 2011-05-15 13:24:11Z ctrondlp $)
# Notes: Basic interaction with Mozilla (Web Browser).  Tested using
#        v1.2.1 of the application under the English language.
#----------------------------------------------------------------------#

## Pragmas/Directives/Diagnostics ##
use strict;
use warnings;

## Imports (use [MODULE] qw/[IMPORTLIST]/;) ##
use X11::GUITest qw/
	StartApp
	FindWindowLike
	WaitWindowClose
	WaitWindowViewable
	SendKeys
	SetEventSendDelay
/;

## Constants (sub [CONSTANT]() { [VALUE]; }) ##

## Variables (my [SIGIL][VARIABLE] = [INITIALVALUE];) ##
my $MainWin = 0;
my $AlertWin = 0;
my $AboutWin = 0;

## Core ##
print "$0 : Script Start\n";

# Slow event sending down a little for when X server
# is busy with this and other bigger applications
SetEventSendDelay(20);

# Make sure Mozilla isn't already running
# even though we could find a way around
# other instances of it.
if (FindWindowLike('Mozilla Firefox')) {
	die('Mozilla Firefox window is already open!');
}

# Start the application
StartApp('firefox');
# Wait at most 20 seconds for it to come up
($MainWin) = WaitWindowViewable('Mozilla Firefox', undef, 20) or die('Could not find browser window!');

# If an alert window presents itself within 5 seconds, close it
if ( (($AlertWin) = WaitWindowViewable('Alert', undef, 5)) ) {
	SendKeys('{SPC}');
	WaitWindowClose($AlertWin) or die('Could not close Alert window!');
}

# Select web address bar and go to a website
SendKeys('^(l)');
SendKeys("http://sourceforge.net/projects/x11guitest\n");
# Wait for website page to start coming up
WaitWindowViewable('X11::GUITest') or die('Could not find website page!');
# Give page time to finish loading, so we can interact with the shortcut keys
# again.  Hopefully we can find a better way in the future rather then hard waits.
sleep(15);

# Open About Mozilla Window
SendKeys('%(h)a'); # Alt-h, a
($AboutWin) = WaitWindowViewable('About.*Mozilla') or die('Could not find About window!');
# Now close it
SendKeys('%(c)');
WaitWindowClose($AboutWin) or die('Could not close About window!');

# Close main Mozilla window
SendKeys('^(w)');
WaitWindowClose($MainWin) or die('Could not close Mozilla window!');


print "$0 : Script End (Success)\n";

## Subroutines ##
