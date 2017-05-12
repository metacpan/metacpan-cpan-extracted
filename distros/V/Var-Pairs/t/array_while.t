use 5.014;
use strict;
use Test::More tests => 13;

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

