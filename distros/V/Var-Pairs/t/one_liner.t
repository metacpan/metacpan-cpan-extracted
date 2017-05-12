use 5.014;
use strict;
use Test::More tests => 3;

use Var::Pairs;

{
    my @results;
    my @data = 'a'..'f';
    for my $next1 (pairs @data) { for my $next2 (pairs @data) {
        push @results, $next1->value . $next2->value;
    }}

    is_deeply \@results, [grep {/^[a-f][a-f]$/} 'aa'..'ff']  => 'nested one-liner';
}

{
    my @results;
    my @data = 'a'..'f';
    for my $next1 (pairs @data, pairs @data) {
        push @results, $next1->value;
    }

    is_deeply \@results, ['a'..'f','a'..'f']  => 'repeated pairs';
}

{
    my @data = 'a'..'f';

    while (my $next_outer = each_pair @data) { while (my $next_inner = each_pair @data) {
            state $count = 0;
            $count++;
            END {
                ok $count == @data * @data => 'correct number of iterations';
            }
    }}
}

