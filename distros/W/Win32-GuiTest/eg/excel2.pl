#!perl -w

# $Id: excel2.pl,v 1.4 2004/07/19 20:20:58 szabgab Exp $
#
# Exercise Win32::GuiTest using MS-Excel. Will only work with non-localized
# versions of Excel (hard-coded hot-keys).
#

use strict;
use Win32::GuiTest qw(FindWindowLike GetWindowText 
SetForegroundWindow SendKeys);

$Win32::GuiTest::debug = 0; # Set to "1" to enable verbose mode

my @windows = FindWindowLike(0, "^Microsoft Excel", "^XLMAIN\$");

die "You should start Excel before running this example.\n"
    unless @windows;

print "$windows[0]>\t'", GetWindowText($windows[0]), "'\n\n";
SetForegroundWindow($windows[0]);
SendKeys("%fn~{PAUSE 1000}");
SendKeys("Randal, look!{TAB}");
SendKeys("Just{TAB}Another{TAB}Perl{TAB}Hacker{TAB}");
SendKeys("{DOWN}{LEFT 5}This is another test!{TAB}{DOWN}{LEFT}");
SendKeys("I hope we're on cell A3!{ENTER}");

my @xl_children = FindWindowLike($windows[0]);
for (@xl_children) {
    print "$_>\t'", GetWindowText($_), "'\n";
}

print "\n";

SendKeys("{PAUSE 2000}%to{PAUSE 2000}");
SendKeys("{ESC}Test finished.{ENTER}");






