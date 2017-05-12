use 5.014;
use strict;
no if $] >= 5.018, warnings => "experimental::smartmatch";
use Test::More tests => 13;

use Var::Pairs;

my %data;
@data{1..6} = ('a'..'f');

for my $next (pairs %data) {
    ok $next->key   ~~ %data              => 'key method correct';
    ok $next->value eq $data{$next->key}  => 'value method correct';
    delete $data{$next->key};
}

ok !keys %data => 'Iterated all';

