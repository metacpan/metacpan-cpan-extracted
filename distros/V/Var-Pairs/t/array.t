use 5.014;
use strict;
use Test::More tests => 12;

use Var::Pairs;

my @data = 'a'..'f';

for my $next (pairs @data) {
    state $count = 0;
    ok $next->index   == $count         => 'index method correct';
    ok $next->value   eq $data[$count]  => 'value method correct';
    $count++;
}

