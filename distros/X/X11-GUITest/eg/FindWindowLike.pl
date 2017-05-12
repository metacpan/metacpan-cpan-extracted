#!/usr/bin/perl
#-----------------------------------------------------------------------------#
# X11::GUITest ($Id: FindWindowLike.pl 203 2011-05-15 02:03:11Z ctrondlp $)
# Notes: Example usage of FindWindowLike
#-----------------------------------------------------------------------------#

## Pragmas/Directives/Diagnostics ##
use strict;
use warnings;

## Imports (use [MODULE] qw/[IMPORTLIST]/;) ##
use X11::GUITest qw/
	FindWindowLike
	GetWindowName
/;

## Constants (sub [CONSTANT]() { [VALUE]; }) ##

## Variables (my [SIGIL][VARIABLE] = [INITIALVALUE];) ##
my @wins = ();

## Core ##
print "$0 : Script Start\n";

# Get list of Ids for all windows 
# (RegExp: .* = zero or more characters, so it will pick up on nameless windows also)
@wins = FindWindowLike('.*') or die("Didn't find any windows!");

# Alternatively, one may use the following syntax in a script if there is
# interest in a specific window:
# my ($win) = FindWindowLike('My Window');

print "FindWindowLike found " . @wins . " window(s).\n";

print "Press <Enter> to display a list of these window(s).";
readline(*STDIN);

# Output a little information for each window
foreach my $win (@wins) {
	my $name = GetWindowName($win) || '[NO NAME]';
	print "\t" . sprintf("0x%X", $win) . " ($name)\n";
}


print "$0 : Script End (Success)\n";

## Subroutines ##
