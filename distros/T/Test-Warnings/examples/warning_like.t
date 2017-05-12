use strict;
use warnings;

# this test demonstrates the issue described in the main documentation, where
# a test of the contents of a captured warning can inadvertently match another
# part of the stack trace (the pattern argument to the test sub, itself!)

use Test::More;
use Test::Warnings ':all';
use Carp 'cluck';

sub warning_like(&$;$)
{
    my ($code, $pattern, $name) = @_;
    like( &warning($code), $pattern, $name );
}

warning_like(sub { cluck 'blah blah' }, qr/foo/, 'foo seems to appear in the warning');

# the test only passes when we invert it
unlike(
    ( warning { cluck 'blah blah' } || '' ),
    qr/foo/,
    'foo does NOT ACTUALLY appear in the warning',
);

done_testing;
