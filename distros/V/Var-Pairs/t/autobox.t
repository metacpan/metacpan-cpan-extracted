use 5.014;
no if $] >= 5.018,               warnings => "experimental::smartmatch";
use Test::More;

plan eval { require autobox }
    ? (tests => 25)
    : (skip_all => 'This test requires autobox, which could not be loaded');

use Var::Pairs;

my @data = 'a'..'f';

for my $next (@data->pairs) {
    state $count = 0;
    ok $next->index   == $count         => 'index method correct';
    ok $next->value   eq $data[$count]  => 'value method correct';
    $count++;
}


my $data_ref = {};
@{$data_ref}{1..6} = ('a'..'f');

while (my $next = $data_ref->each_pair) {
    ok $next->key     ~~ $data_ref               => 'key method correct';
    ok $next->value   eq $data_ref->{$next->key} => 'value method correct';
    delete $data_ref->{$next->key};
}

ok !keys %{$data_ref} => 'Iterated all';


