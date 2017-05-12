#
# $Id: 01-basic.t,v 0.1 2006/12/21 21:30:29 dankogai Exp $
#
use strict;
use warnings;
#use Test::More qw/no_plan/;
use Test::More tests=>306;
use Tie::Array::Pack;

local $"=","; local $\="\n";
my @fmt = qw/c C s S i I l L n N v V j J f d F f/;
for my $fmt (@fmt){
    my @a;
    tie my @t, 'Tie::Array::Pack' => $fmt;

    print "# fmt = $fmt";
    is_deeply \@a, \@t, "(@a)==(@t)";

    @t = @a = (1..4);
    is_deeply \@a, \@t, "(@a)==(@t)";

    $a[$_]-- for (0..@a-1); $t[$_]-- for (0..@t-1);
    is_deeply \@a, \@t, "-- => (@a)==(@t)";

    push @a, (4..7); push @t, (4..7);
    is_deeply \@a, \@t, "pushed => (@a)==(@t)";
    
    unshift @a, (8..11); unshift @t, (8..11);
    is_deeply \@a, \@t, "unshifted (@a)==(@t)";

    my $a = pop @a; my $t = pop @t;
    is $a, $t, "pop => $a == $t";
    is_deeply \@a, \@t, "popped => (@a)==(@t)";

    $a = shift@a; $t = shift @t;
    is $a, $t, "shift => $a == $t";
    is_deeply \@a, \@t, "shifted => (@a)==(@t)";

    my @A = splice(@a, 1, 2, 3, 4); my @T = splice(@t, 1, 2, 3, 4); 
    is_deeply \@A, \@T, "splice => (@A)==(@T)";
    is_deeply \@a, \@t, "spliced => (@a)==(@t)";
    @A = splice(@a, 1, 2, 3); @T = splice(@t, 1, 2, 3); 
    is_deeply \@A, \@T, "splice => (@A)==(@T)";
    is_deeply \@a, \@t, "spliced => (@a)==(@t)";
    @A = splice(@a, 1, 2); @T = splice(@t, 1, 2); 
    is_deeply \@A, \@T, "splice => (@A)==(@T)";
    is_deeply \@a, \@t, "spliced => (@a)==(@t)";
    @A = splice(@a, 1); @T = splice(@t, 1); 
    is_deeply \@A, \@T, "splice => (@A)==(@T)";
    is_deeply \@a, \@t, "spliced => (@a)==(@t)";

}
