#!perl -T

use warnings;
use strict;

BEGIN {
    for($0, $^X) { ## no critic (Variables::ProhibitPunctuationVars)
        ($_) = /(.*)/;
    }
}

use Test::More;
use Test::Taint tests => 10;

use constant VAR => 'VAR'; ## no critic (ValuesAndExpressions::ProhibitConstantPragma)

taint_checking_ok();

my $foo = 43;
untainted_ok( $foo, 'Starts clean' );
taint($foo);
tainted_ok( $foo, 'Gets dirty' );
$foo =~ /(\d+)/ or die;
$foo = $1;
untainted_ok( $foo, 'Reclean' );

my $bar = 'bar';
untainted_ok( $bar, 'Starts clean' );
taint($bar);
tainted_ok( $bar, 'Gets dirty' );
is($bar, 'bar', 'String value stays the same');

untainted_ok( VAR, 'Starts clean' );
taint(VAR);
untainted_ok( VAR, 'Stays clean' );
is(VAR, 'VAR', 'String value stays the same');
