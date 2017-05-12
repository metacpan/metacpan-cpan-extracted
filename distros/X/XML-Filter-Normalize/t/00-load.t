#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'XML::Filter::Normalize' );

my $ver = XML::Filter::Normalize->VERSION;
diag( "Testing XML::Filter::Normalize $ver, Perl $], $^X" );

# vim: set ai et sw=4 syntax=perl :
