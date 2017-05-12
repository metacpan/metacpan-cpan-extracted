use strict;
use warnings;
use Test::More tests => 5;

use signatures;

sub foo ($bar) { $bar }

sub korv ($wurst, undef, $birne) {
    return "${wurst}-${birne}";
}

sub array ($scalar, @array) {
    return $scalar + @array;
}

sub hash (%hash) {
    return keys %hash;
}

sub Name::space ($moo) { $moo }

is(foo('baz'), 'baz');
is(korv(qw/a b c/), 'a-c');
is(array(10, 1..10), 20);
is_deeply(
    [sort(hash(foo => 1, bar => 2))],
    [sort(qw/foo bar/)],
);

is(Name::space('kooh'), 'kooh');
