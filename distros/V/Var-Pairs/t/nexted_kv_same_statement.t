use 5.014;
use strict;
use Test::More;

use Var::Pairs;

my @data = 'a'..'f';

plan tests => 1 + 2 * @data;

my ($iter1, $iter2);
while (my ($key1, $val1) = each_kv(@data) and my ($key2, $val2) = each_kv(@data)) {
    state $count = 0;
    $count++;
    is $key1, $key2 => "Iterated key in parallel ($key1)";
    is $val1, $val2 => "Iterated value in parallel ($val1)";
    END {
        cmp_ok $count, '==', @data => "correct number of iterations";
    }
}



