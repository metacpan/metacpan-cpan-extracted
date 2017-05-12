#!perl -T

use warnings;
use strict;

use Test::Taint tests=>3;

my @keys = keys %ENV;
my $key = shift @keys;

taint_checking_ok();
tainted_ok( $ENV{$key}, "\$ENV{$key} is tainted" );

my $foo = 43;
untainted_ok( $foo );
