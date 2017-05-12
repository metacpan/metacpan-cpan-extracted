use 5.014;
use strict;
use Test::More tests => 24;

use Var::Pairs;

my %data;
@data{1..6} = ('a', 2, 'c', 4, 'e', 6);

for my $next (pairs %data) {
    ok $next                                           => 'Pair boolified as expected';
    if ($next->key % 2) {
        is "$next", $next->key . ' => "' . $next->value . '"'  => 'Stringified as expected';
    }
    else {
        is "$next", $next->key . ' => '  . $next->value        => 'Stringified as expected';
    }
    ok !defined eval { 0 + $next }                     => 'Failed to numerify (as expected)';
    like $@, qr/Can't convert Pair\(.*?\) to a number/ => 'Appropriate error message';
}

