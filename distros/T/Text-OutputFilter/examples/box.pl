#!/usr/bin/perl

use strict;
use warnings;

use Text::OutputFilter;

my $width = $ENV{COLUMNS} || 80;
   $width--;
   $width < 5 and die "Width should be > 4\n";
my $txtw   = $width - 4;
my $txtfmt = "# %-${txtw}.${txtw}s #";

print "#" x $width, "\n";

tie *STDOUT, "Text::OutputFilter", 0, *STDOUT, sub {
    sprintf $txtfmt, $_[0];
    };

print <>;
close STDOUT;

untie *STDOUT;
print "#" x $width, "\n";
