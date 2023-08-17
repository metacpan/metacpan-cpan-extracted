use 5.014;
no if $] >= 5.018,               warnings => "experimental::smartmatch";
use strict;
use Test::More tests => 13;

use Var::Pairs;

my $data_ref = {};
@{$data_ref}{1..6} = ('a'..'f');
my @keys = keys %{$data_ref};

for my $next (pairs $data_ref) {
    ok exists $data_ref->{$next->key}            => 'key method correct';
    ok $next->value   eq $data_ref->{$next->key} => 'value method correct';
    delete $data_ref->{$next->key};
}

ok !keys %{$data_ref} => 'Iterated all';

