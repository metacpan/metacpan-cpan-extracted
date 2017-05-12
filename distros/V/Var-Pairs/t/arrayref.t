use 5.014;
use strict;
use Test::More tests => 12;

use Var::Pairs;

my $data_ref = ['a'..'f'];

for my $next (pairs $data_ref) {
    state $count = 0;
    ok $next->index   == $count              => 'index method correct';
    ok $next->value   eq $data_ref->[$count] => 'value method correct';
    $count++;
}

