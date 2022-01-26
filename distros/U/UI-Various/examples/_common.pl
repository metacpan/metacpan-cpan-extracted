#!/usr/bin/perl

# see README.md for documentation and license

# _common.pl is an include file for the examples for UI::Various.  It
# separates the selection of the user interface from the real example code,
# allowing the example scripts to focus only on the code needed.  In
# addition it defines the default code restrictions (C<strictures> etc.).

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Cwd;

BEGIN {
    my $cwd = cwd();
    $cwd =~ s|/examples/?$||;
    unshift @INC, $cwd.'/lib'  if  $cwd =~ m|UI-Various(?:-\d\.\d+)?$|;
}

use constant PACKAGES => qw(Tk Curses RichTerm PoorTerm);
my @packages;
BEGIN {
    @packages = PACKAGES;
    0 < @ARGV  and  $ARGV[0] =~ m/^[1-4]$/
	and  @packages = ((PACKAGES)[$ARGV[0] - 1]);
}
use UI::Various({use => [@packages], log => 'INFO'});

#########################################################################
# handle '-?' or bad parameters:
unless (0 == @ARGV  or
	1 == @ARGV  and  $ARGV[0] =~ m/^([1-4]|-[h?]|--help)$/i)
{
    die "\n", 'usage: ', $0, " [1|2|3|4|-?|-h|--help]\n";
}
unless (0 == @ARGV  or  $ARGV[0] =~ m/\d/)
{
    warn("\n", 'usage: ', $0, " [1|2|3|4|-?|-h|--help]\n\n",
	 "The example knows the following UIs:\n\n");
    warn $_+1, "\t", $packages[$_], "\n" foreach 0..$#packages;
    exit 0;
}
UI::Various::stderr(2)  if  'Curses' eq UI::Various::using();
