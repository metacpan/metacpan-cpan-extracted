#!/usr/bin/perl -w

use strict;
use warnings;

use Text::Widont qw( nbsp );

my $tw = Text::Widont->new( nbsp => nbsp->{html} );

my $string = "I'm selling these fine leather jackets.\n";
print $tw->widont($string);
