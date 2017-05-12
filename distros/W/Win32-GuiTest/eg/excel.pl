#!perl -w
# $Id: excel.pl,v 1.4 2004/07/19 20:20:58 szabgab Exp $
#

use strict;

use Win32::GuiTest qw(FindWindowLike GetWindowText SetForegroundWindow);

$Win32::GuiTest::debug = 0; # Set to "1" to enable verbose mode

# Find top level (1) windows containg Excel in their title
my @windows = FindWindowLike(undef, "Excel", "", undef, 1);
for (@windows) {
    print "$_>\t'", GetWindowText($_), "'\n";
}
print "------------\n";

# Find all windows matching Microsoft Excel in the title, and XLMAIN$
# as the class. 
@windows = FindWindowLike(undef, "^Microsoft Excel", "^XLMAIN\$");
for (@windows) {
    print "$_>\t'", GetWindowText($_), "'\n";
    SetForegroundWindow($_);
}
print "------------\n";

die "You should start Excel before running this example.\n"
    unless @windows;

# Find all children of a specified window.
my @children = FindWindowLike($windows[0]);
for (@children) {
    print "$_>\t'", GetWindowText($_), "'\n";
}
