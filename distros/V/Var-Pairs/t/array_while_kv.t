use 5.014;
use strict;
use Test::More tests => 34;

use Var::Pairs;

my @data = 'a'..'f';

while (my ($next_index, $next_value) = each_kv @data) {
    state $count = 0;
    ok $next_index   == $count         => 'index method correct';
    ok $next_value   eq $data[$count]  => 'value method correct';
    $count++;

    END {
        ok $count == @data              => 'correct number of iterations';
    }
}

# Test that iterators in nested loops also reset...
my $recount = 0;
for (1..2) {
    my $count = 0;
    while (my ($next_index, $next_value) = each_kv @data) {
        ok $next_index   == $count         => 'nested index method correct';
        ok $next_value   eq $data[$count]  => 'nested value method correct';
        $count++;
        $recount++;
        last if $count > 4;
    }
}

ok $recount == 10              => 'correct number of re-iterations';

