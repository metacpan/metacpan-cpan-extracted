#!perl -T

use warnings;
use strict;

use Test::Taint tests=>3;

taint_checking_ok();
tainted_ok( $^X, '$^X is tainted' );

my $foo = 43;
untainted_ok( $foo );
