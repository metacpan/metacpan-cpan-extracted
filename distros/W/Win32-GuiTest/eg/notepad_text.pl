#!perl -w
# $Id: notepad_text.pl,v 1.3 2004/07/21 17:47:38 szabgab Exp $
# If you have a notepad window open this prints the contents.

use strict;

use Win32::GuiTest qw(FindWindowLike WMGetText);

my @windows = FindWindowLike(0, "", "Notepad");
die "More than one notepad open\n" if @windows > 1;
die "No notepad is running, please open one with some text in it.\n" if not @windows;

my $notepad = $windows[0];
my @edits = FindWindowLike($notepad, "", "Edit");
die "More than one edit inside notepad: " .  @edits . "\n" if @edits > 1;
die "No edit window found inside notepad\n" if not @edits;

print "----------------------------------------------------------\n";
print WMGetText($edits[0]);
print "\n";
print "----------------------------------------------------------\n";


