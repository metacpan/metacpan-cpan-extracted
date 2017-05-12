use strict;
use warnings;
use Test::More;

BEGIN {
    eval 'use Perl6::Junction';
    plan skip_all => 'Perl6::Junction required' if $@;
    plan tests => 1;
}

use signatures;

sub foo ($bar) {
    return $bar;
}

is(foo('moo'), 'moo');
