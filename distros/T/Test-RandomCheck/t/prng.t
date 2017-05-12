use strict;
use warnings;
use Test::RandomCheck;
use Test::RandomCheck::PRNG;
use Test::RandomCheck::Generator;
use Test::More;

random_ok {
    my ($range1, $range2) = @_;
    my $mlcg = Test::RandomCheck::PRNG->new;
    my $n = $mlcg->next_int($range1, $range2);
    my ($min, $max) = $range1 < $range2 ? ($range1, $range2)
                                        : ($range2, $range1);
    $min <= $n && $n <= $max;
} concat(integer, integer);

done_testing;
