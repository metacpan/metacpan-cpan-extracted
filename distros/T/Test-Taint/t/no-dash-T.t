#!perl -w
# Note the lack of -T in the shebang

use warnings;
use strict;

use Test::Taint tests=>4;
use Test::More;

ok( !taint_checking(), 'Taint checking is off' );

my $foo = 43;
untainted_ok( $foo, 'Starts clean' );
taint($foo);
untainted_ok( $foo, 'Stays clean' );
untainted_ok( $Test::Taint::TAINT );
