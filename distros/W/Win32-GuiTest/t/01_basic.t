#!perl -w
BEGIN {
	print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
	$| = 1;
}

# $Id: 01_basic.t,v 1.4 2010/06/13 18:45:09 int32 Exp $

use strict;
use Test::More qw(no_plan);

use Win32::GuiTest qw(:ALL);


# Check that there are no duplicate windows in the list
my @wins = FindWindowLike();
my %found;
my $dup;
for (@wins) {
    $dup = 1 if $found{$_};
    $found{$_} = 1;
}
ok(@wins, "Check there are windows");
ok(!$dup, "No duplicates");

# Just use SenKeys as pause
SendKeys("{PAUSE 1000}");
ok(1);

# The desktop should never be on the window list
my $root = GetDesktopWindow();
my @desks = grep { $_ == $root } @wins;
ok(! @desks, "The desktop is not on the window list");

# Make sure there are no existing Notepad windows to interfere with testing
{
    my @notepad_windows = FindWindowLike(0, "", "Notepad");
    BAIL_OUT('Please close existing Notepad windows before proceeding')
        if @notepad_windows;
}

# Create a notepad window and check we can find it
system("cmd /c start notepad.exe \"README\"");
my @waitwin = WaitWindowLike(0, "readme|README", "Notepad");
is(@waitwin, 1, "There is one notepad open with README in it");
my @windows = FindWindowLike(0, "readme|README", "Notepad");
is(@windows, 1, "The same from FindWindowLike");
is($waitwin[0], $windows[0], "The two windows are the same");

# Find the edit window inside notepad
my $notepad = $windows[0];
my @edits = FindWindowLike($notepad, "", "Edit");
is(@edits, 1, "Edit window found within notepad");

# Get the contents (should be the GuiTest.pm file)
my $content = WMGetText($edits[0]);
# Make CRLF into LF
$content =~ s/\r\n/\n/gs;
SendKeys("%{F4}");
open(GUI_FILE, "<README");
my @lines = <GUI_FILE>;
close GUI_FILE;
my $file_content = join('', @lines);
like($content, qr/Win32::GuiTest/,      "we have Win32::GuiTest in the text");
like($file_content, qr/Win32::GuiTest/, "in the file too");
$content =~ s/\x0d\x0a/\n/gs;
$file_content =~ s/\x0d\x0a/\n/gs;
is($content eq $file_content, 1, "file is identical to what is in notepad");

# Open a notepad and type some text into it
system("cmd /c start notepad.exe");
@waitwin = WaitWindowLike(0, "", "Notepad");
is(@waitwin, 1, "New notepad opened");
@windows = FindWindowLike(0, "", "Notepad");
is(@windows, 1, "same here");
is($waitwin[0], $windows[0], "WindowIDs are identical");

SetForegroundWindow($windows[0]);
SendKeys(<<EOM, 10);
    This is a test message,
    but also a little demo for the
    SendKeys function.
    3, 2, 1, 0...
    Closing Notepad...
EOM
    
SendKeys("{PAU 1000}%{F4}{TAB}{ENTER}");

# We closed it so there should be no notepad open
@windows = FindWindowLike(0, "", "Notepad");
is(@windows,0, "No notepad open now");

# Since we are looking for child windows, all of them should have
# depth of 1 or more
# SZABGAB sais This is buggy here !
my $desk = GetDesktopWindow();
my @childs =  GetChildWindows($desk);
my @badchilds = grep {  GetChildDepth($desk, $_) < 1  } @childs;
is(@badchilds, 0, "no children with less that 1 Depth");

# If you do not specify patterns, etc, FindWindowLike is equivalent to
# GetChildWindows (meaning all the windows)
my @all = GetChildWindows($desk);
my @some = FindWindowLike($desk);
is_deeply(\@all, \@some, "FindWindowLike and GetChildWindows are the same here");

# Look for any MFC windows and do sanity check
my @mfc = FindWindowLike($desk, "", "^[Aa]fx");
is_deeply([grep { GetClassName($_) =~ /^[aA]fx/  } @mfc], \@mfc, "MFC windows sanity check");

# Look for any sys windows and do sanity check
my @sys = FindWindowLike($desk, "", "^Sys");
is_deeply([grep { GetClassName($_) =~ /^Sys/  } @sys], \@sys, "sys windows sanity check");

# Loop increasing window search depth until increasing the depth returns
# no more windows
my $depth = 1;
@wins = FindWindowLike($desk, "", "", undef, $depth);
my @next = FindWindowLike($desk, "", "", undef, $depth+1);
while (scalar(@next) > scalar(@wins)) {
    $depth++;
    @wins = @next;
    @next = FindWindowLike($desk, "", "", undef, $depth+1);
}

# The maximum reached depth should contain all the windows
is_deeply([FindWindowLike($desk, "", "", undef, $depth)], \@all);

# The maximum reached depth should contain all the windows
my ($x, $y) = GetScreenRes();
cmp_ok($x, ">", 0, "x coordinate is greater than 0");
cmp_ok($y, ">", 0, "y coordinate is greater than 0");

# Window size of the desktop should be bigger or the same as the screen resolution
# Always???
my ($left, $top, $right, $bottom) = GetWindowRect($desk);
cmp_ok(($right-$left), ">=", $x);
cmp_ok(($bottom-$top), ">=", $y);


