#!/usr/bin/perl
# $Id: wptr.pl,v 1.4 2004/07/22 22:25:13 ctrondlp Exp $
#

# Module Pragmas
use strict;
use warnings;

# Module Imports
use Win32::GuiTest qw(GetCursorPos GetClassName GetWindowText
	GetWindowRect WindowFromPoint GetWindowID IsKeyPressed WMGetText);
use Win32::Clipboard;

# Module Level Variables
my $Clip = Win32::Clipboard();
my $cur_info = "";
my $oldhwnd = 0;
my $oldcx = 0;
my $oldcy = 0;

# Core Loop
while (1) {
	my ($cx, $cy) = GetCursorPos();
	# Is different cursor position?
	if ( ($cx != $oldcx) || ($cy != $oldcy) ) {
		$oldcx = $cx;
		$oldcy = $cy;
		# Get handle of window
		my $hwnd = WindowFromPoint($cx, $cy);
		if ($hwnd == $oldhwnd) {
			# Same window as before, don't query information again.
			next;
		}
		# Different window, so cache the handle value.
		$oldhwnd = $hwnd;
		# Get information for the new window in which the cursor is over.
		$cur_info = GetWindowInfo($hwnd);
		ClearScreen();
		# Output window information to console.
		DispWindowInfo($cur_info);
		# Display menu.
		DispMenu();
	}
	# INSERT to copy window data to clipboard.
	if (IsKeyPressed("INS")) {
		$Clip->Empty();
		$Clip->Set($cur_info);
		select(undef, undef, undef, 0.50);
		print "Copied data to clipboard.\n";
	}
	# ESCAPE to exit this program.
	if (IsKeyPressed("ESC")) {
		print "Goodbye!\n";
		last;
	}
}


sub ClearScreen {
	system("command /c cls");
	return;
}

sub GetWindowInfo {
	my $hwnd = shift;
	my $info = 		"# Window Text: '" . GetWindowText($hwnd) . "'\r\n";
	$info = $info . "# Window Class: '" . GetClassName($hwnd) . "'\r\n";
	$info = $info . "# Window ID: " . GetWindowID($hwnd) . "\r\n";
	my ($left, $top, $right, $bottom) = GetWindowRect($hwnd);
	$info = $info . "# Window Rect: ($left, $top) - ($right, $bottom)\r\n";
print "Text: " . WMGetText($hwnd) . "\r\n";
	return($info);
}

sub DispWindowInfo {
	print shift;
	return;
}

sub DispMenu {
	print "\n\nPress <INSERT> to copy window text to clipboard.\n";
	print "Press <ESCAPE> to exit program.\n";
	return;
}
