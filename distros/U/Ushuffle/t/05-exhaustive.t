use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use UshuffleTest;

use Ushuffle qw(shuffle set_seed);

# For sequences short enough to list every valid shuffle by brute force,
# check that the library produces exactly that set, and each member equally
# often. The seed is fixed, so a run gives the same result every time on a
# given platform.

set_seed(20260930);

# sequence, let size, number of valid shuffles
my @cases = (
    [ 'A',                    1, 1 ],
    [ 'AAB',                  1, 3 ],
    [ 'ACGU',                 1, 24 ],
    [ 'AACGU',                1, 60 ],
    [ 'ABA',                  2, 1 ],
    [ 'ACGU',                 2, 1 ],
    [ 'ACACACAC',             2, 1 ],
    [ 'AABAB',                2, 2 ],
    [ 'GAUUACAGAUUACA',       2, 90 ],
    [ 'ACACGUAGAUGGGGA',      2, 1200 ],
    [ 'AACAGAUACGUAGCA',      2, 2880 ],
    [ 'ABAB',                 3, 1 ],
    [ 'AAGAUAAGAUAAGA',       3, 1 ],
    [ 'ACGUACGAUCAGUCAGA',    3, 4 ],
    [ 'ACGACGUACGAACGU',      3, 6 ],
    [ 'AUAUAUGAUAUAGAUAUA',   3, 30 ],
    [ 'ACGUACGUAACGUUACGU',   4, 6 ],
    [ 'AAACAAAGAAACAAAUAAAC', 4, 12 ],
);

for my $case (@cases) {
    my ($seq, $k, $count) = @$case;
    my $name = "$seq, k=$k";

    my %valid = map { $_ => 0 } all_shuffles($seq, $k);
    is scalar keys %valid, $count, "$name: $count valid shuffles exist";
    ok exists $valid{$seq}, "$name: the sequence is one of them";

    # draw until every valid shuffle has been seen; a correct sampler needs
    # far fewer draws than the limit
    my $shuffler = Ushuffle::Shuffler->new($seq, $k);
    my ($invalid, $unseen, $draws) = (0, $count, 0);
    while ($unseen && $draws < 50 * $count + 100) {
        my $out = $draws++ % 2 ? shuffle($seq, $k) : $shuffler->shuffle;
        if    (!exists $valid{$out}) { $invalid++ }
        elsif (!$valid{$out}++)      { $unseen-- }
    }
    is $invalid, 0, "$name: only valid shuffles are produced";
    is $unseen,  0, "$name: every valid shuffle is produced";
}

# each valid shuffle must come up equally often
for my $case (grep { $_->[2] > 1 && $_->[2] <= 100 } @cases) {
    my ($seq, $k, $count) = @$case;
    my $expected = 500;

    for my $via ('shuffle()', 'Shuffler') {
        my $shuffler = Ushuffle::Shuffler->new($seq, $k);
        my %seen;
        for (1 .. $expected * $count) {
            $seen{ $via eq 'Shuffler' ? $shuffler->shuffle : shuffle($seq, $k) }++;
        }
        my $chi2 = 0;
        $chi2 += ($_ - $expected)**2 / $expected for values %seen;
        $chi2 += $expected * ($count - keys %seen);

        cmp_ok $chi2, '<', chi2_limit($count - 1),
            sprintf '%s, k=%d via %s: %d shuffles are equally likely (chi-square %.1f)',
            $seq, $k, $via, $count, $chi2;
    }
}

# the two ends of a shuffle are fixed, the letters in between are not
{
    my $seq = 'ACGUACGAUCGGAUUAGCAUGC';
    my @at;
    for (1 .. 2000) {
        my @letters = split //, shuffle($seq, 2);
        $at[$_]{ $letters[$_] }++ for 0 .. $#letters;
    }
    is join('', keys %{ $at[0] }),  'A', 'first letter never changes for k=2';
    is join('', keys %{ $at[-1] }), 'C', 'last letter never changes for k=2';
    my @frozen = grep { keys %{ $at[$_] } == 1 } 1 .. $#at - 1;
    is "@frozen", '', 'every inner position sees more than one letter';
}

done_testing;
