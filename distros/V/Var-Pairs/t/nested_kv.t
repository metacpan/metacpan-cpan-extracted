use 5.014;
use strict;
use Test::More tests => 1;

use Var::Pairs;

my @data = 'a'..'f';

while (my ($next_outer) = each_kv @data) { while (my ($next_inner) = each_kv @data) {
        state $count = 0;
        $count++;
        END {
            cmp_ok $count, '==', @data * @data => "correct number of iterations";
        }
    }
}


