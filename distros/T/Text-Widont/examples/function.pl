#!/usr/bin/perl -w

use strict;
use warnings;

use Text::Widont;

# For a single string...
my $string = "Look behind you, a Three-Headed Monkey!\n";
print widont($string, nbsp->{html});


# For a number of strings...
my $strings = [
    'You fight like a dairy farmer.',
    'How appropriate. You fight like a cow.',
];
print join "\n", @{ widont( $strings, nbsp->{html} ) };
print "\n";
