use 5.014;
use strict;
use Test::More tests => 34;

use Var::Pairs;

my @data = 'a'..'f';

while (my $next = each_pair @data) {
    state $count = 0;
    ok $next->index   == $count         => 'index method correct';
    ok $next->value   eq $data[$count]  => 'value method correct';
    $count++;

    END {
        ok $count == @data              => 'correct number of iterations';
    }
}

# Test that iterators in nested loops also reset...
my $recount = 0;
for (1..2) {
    my $count = 0;
    while (my $next = each_pair @data) {
        ok $next->index   == $count         => 'nested index method correct';
        ok $next->value   eq $data[$count]  => 'nested value method correct';
        $count++;
        $recount++;
        last if $count > 4;
    }
}

ok $recount == 10              => 'correct number of re-iterations';

