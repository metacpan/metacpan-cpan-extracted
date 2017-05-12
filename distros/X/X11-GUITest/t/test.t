#!/usr/bin/perl
# X11::GUITest ($Id: test.t 241 2014-03-16 11:39:42Z ctrondlp $)
# Note: Functions that might be too intrusive are not checked

BEGIN {
	$| = 1;

	# Is X info not available? 
	if (!defined($ENV{'DISPLAY'}) || length $ENV{'DISPLAY'} <= 0) {
 		warn "X11::GUITest - X Windows not running or DISPLAY not set.\n"; 
		print "1..1\n";
		print "ok 1\n";
		exit(0);	
	}
	# Testing too ambiguous for varied environments
	if (defined($ENV{'AUTOMATED_TESTING'}) && $ENV{'AUTOMATED_TESTING'}) {
 		warn "X11::GUITest - Not performing extensive tests.\n"; 
		print "1..1\n";
		print "ok 1\n";
		exit(0);	
	}

	# Pre-checks ok, so plan on running the tests.
	print "1..24\n";
}
END {
	print "not ok 1\n" unless $loaded;
}

use X11::GUITest qw/
	:ALL
/;
$loaded = 1;
print "ok 1\n";

use strict;
use warnings;

# Used for testing below
my $BadWinTitle = 'BadWindowNameNotToBeFound';
my $BadWinId = '898989899';
my @Windows = ();
my $HasWindows = 0;

# Determine if there are windows to use.  If tester
# is using xvfb-run, we'll likely have 0 windows.
$HasWindows = (scalar FindWindowLike(".*"));


# FindWindowLike
if ($HasWindows) {
	print "not " unless FindWindowLike(".*");
}
print "not " unless not FindWindowLike($BadWinTitle);
print "ok 2\n";

# WaitWindowClose
print "not " unless WaitWindowClose($BadWinId);
print "ok 3\n";

# WaitWindowLike
if ($HasWindows) {
	print "not " unless WaitWindowLike(".*");
}
print "not " unless not WaitWindowLike($BadWinTitle, undef, 1);
print "ok 4\n";

# WaitWindowViewable
if ($HasWindows) {
	print "not " unless WaitWindowViewable(".*");
}
print "not " unless not WaitWindowViewable($BadWinTitle, undef, 1);
print "ok 5\n";

# ClickWindow
# StartApp
# RunApp
# SetEventSendDelay
# GetEventSendDelay
# SetKeySendDelay
# GetKeySendDelay

# GetWindowName
my $WinName = ''; 
# Note: Only worry about windows that have a name
# RegExp: ".+" = one or more characters
foreach my $win (FindWindowLike(".+")) {
	# If call fails, WinName will be set to undef
	$WinName = GetWindowName($win);
	if (not defined($WinName)) {
		last;
	}
}
print "not " unless defined($WinName);
print "ok 6\n";

# SetWindowName

# GetRootWindow
print "not " unless GetRootWindow();
print "ok 7\n";

# GetChildWindows
if ($HasWindows) {
	print "not " unless GetChildWindows(GetRootWindow());
} else {
	print "not " unless not GetChildWindows(GetRootWindow());
}
print "ok 8\n";

# MoveMouseAbs
print "not " unless MoveMouseAbs(2, 2);
print "ok 9\n";

# Give some respite to the X server
sleep 1;

# ClickMouseButton

# SendKeys

# IsWindow
print "not " unless IsWindow(GetRootWindow());
print "not " unless not IsWindow($BadWinId);
print "ok 10\n";

# IsWindowViewable
if ($HasWindows) {
	@Windows = WaitWindowViewable(".*");
	if (not IsWindow($Windows[0])) { # First window not viewable
		$Windows[0] = GetRootWindow(); # Fall-back to root
	}
	print "not " unless IsWindowViewable($Windows[0]);
}
print "not " unless not IsWindowViewable($BadWinId);
print "ok 11\n";

# MoveWindow
# ResizeWindow
# IconifyWindow
# UnIconifyWindow
# Raise Window
# LowerWindow

# SetInputFocus

# GetInputFocus
print "not " unless GetInputFocus();
print "ok 12\n";

# GetWindowPos
my ($x, $y, $width, $height) = GetWindowPos(GetRootWindow());
print "not " unless (defined($x) and defined($y) and
					 defined($width) and defined($height));
print "ok 13\n";

# GetScreenRes
print "not " unless GetScreenRes();
print "ok 14\n";

# GetScreenDepth
print "not " unless GetScreenDepth();
print "ok 15\n";

# GetMousePos
my @coords = ();
print "not " unless ( @coords = GetMousePos() );
print "ok 16\n";

# IsChild
if ($HasWindows) {
	print "not " unless ( @Windows = GetChildWindows(GetRootWindow()) );
	# Note: Limiting check to a certain number of windows (10)
	foreach my $win ( @Windows[0..(9 < $#Windows ? 9 : $#Windows)] ) {
		if (!IsChild(GetRootWindow(), $win)) {
			print "not ";
			last;
		}
	}
}
print "ok 17\n";

# IsKeyPressed
# IsMouseButtonPressed

# QuoteStringForSendKeys
print "not " unless defined( QuoteStringForSendKeys('~!@#$%^&*()_+') );
print "ok 18\n";
print "not " unless (QSfSK('~!@#$%^&*()_+') eq '{~}!@#${%}{^}&*{(}{)}_{+}');
print "ok 19\n";
print "not " unless not defined ( QuoteStringForSendKeys(undef) );
print "ok 20\n";

# GetParentWindow
print "not " unless not GetParentWindow(GetRootWindow());
print "ok 21\n";
if ($HasWindows) {
	print "not " unless GetParentWindow($Windows[0]);
}
print "ok 22\n";

# GetWindowFromPoint
# Note: Using invalid window position of (-1500 x -1500) for testing. 
print "not " unless not GetWindowFromPoint(-1500, -1500);
print "ok 23\n";
if ($HasWindows) {
	print "not " unless GetWindowFromPoint(0, 0);
}
print "ok 24\n";

# PressKey
# ReleaseKey
# PressReleaseKey
# PressMouseButton
# ReleaseMouseButton
# GetWindowPid
# GetWindowsFromPid

