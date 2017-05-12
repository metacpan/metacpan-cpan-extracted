use 5.014;
use strict;
use Test::More tests => 1;

use Var::Pairs;

my @data = 'a'..'f';

while (my $next_outer = each_pair @data) { while (my $next_inner = each_pair @data) {
        state $count = 0;
        $count++;
        END {
            ok $count == @data * @data => 'correct number of iterations';
        }
    }
}

