use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use UshuffleTest;

use Ushuffle qw(shuffle);

# Long sequences, which exercise the library's hash table and graph far
# more than the short ones of the other tests.

srand 7;

sub check {
    my ($name, $in, $out, $k) = @_;
    is length $out, length $in, "$name: length";
    ok klets($out, 1) eq klets($in, 1), "$name: letter counts";
    ok klets($out, $k) eq klets($in, $k), "$name: $k-let counts" if $k > 1;
}

{
    my $rna = random_sequence(200_000, 'ACGU');
    for my $k (1, 2, 3, 6, 12) {
        my $out = shuffle($rna, $k);
        check("200,000 nucleotides, k=$k", $rna, $out, $k);
        ok $out ne $rna, "200,000 nucleotides, k=$k: result differs from the input";
    }

    my $shuffler = Ushuffle::Shuffler->new($rna, 2);
    my %seen;
    for my $round (1 .. 3) {
        my $out = $shuffler->shuffle;
        check("200,000 nucleotides, shuffler round $round", $rna, $out, 2);
        $seen{$out}++;
    }
    is scalar keys %seen, 3, 'three different shuffles from one shuffler';

    # a short sequence in between must not disturb the long one
    is shuffle('ACGU', 2), 'ACGU', 'short sequence in between';
    check('200,000 nucleotides, after a short sequence', $rna, $shuffler->shuffle, 2);
}

{
    my $protein = random_sequence(100_000, 'ACDEFGHIKLMNPQRSTVWY');
    check("100,000 amino acids, k=$_", $protein, shuffle($protein, $_), $_) for 1, 2, 3;
}

{
    my $bytes = random_sequence(100_000, join '', map { chr } 1 .. 255);
    check("100,000 arbitrary bytes, k=$_", $bytes, shuffle($bytes, $_), $_) for 1, 2;
}

# long sequences with a single valid shuffle
{
    my $repeat = 'AC' x 100_000;
    ok shuffle($repeat, 2) eq $repeat, 'long dinucleotide repeat, k=2';

    my $blocks = 'A' x 50_000 . 'C' x 50_000;
    ok shuffle($blocks, 2) eq $blocks, 'two long homopolymer blocks, k=2';
    my $mixed = shuffle($blocks, 1);
    ok $mixed ne $blocks, 'two long homopolymer blocks, k=1: mixed';
    is $mixed =~ tr/A//, 50_000, 'two long homopolymer blocks, k=1: letter counts';

    my $poly = 'A' x 300_000;
    ok shuffle($poly, 5) eq $poly, 'long homopolymer, k=5';
}

# let sizes close to the length
{
    my $in = random_sequence(5_000, 'ACGU');
    for my $k (4_990, 4_999, 5_000, 5_001) {
        ok shuffle($in, $k) eq $in, "5,000 nucleotides, k=$k";
    }
}

# Beyond roughly 17 million characters, k=6 used to overflow an int in the
# library's hash function: a crash on x86_64, a slowdown by an order of
# magnitude elsewhere. This needs about 1 GB of memory.
SKIP: {
    skip 'set EXTENDED_TESTING to shuffle 25 million nucleotides', 4
        unless $ENV{EXTENDED_TESTING};

    my $huge = random_sequence(1_000_000, 'ACGU') x 25;
    my $out  = shuffle($huge, 6);
    is length $out, length $huge, '25 million nucleotides, k=6: length';
    is join(',', map { eval "\$out =~ tr/$_//" } qw(A C G U)),
        join(',', map { eval "\$huge =~ tr/$_//" } qw(A C G U)),
        '25 million nucleotides, k=6: letter counts';
    ok klets($out, 6) eq klets($huge, 6), '25 million nucleotides, k=6: 6-let counts';
    ok $out ne $huge, '25 million nucleotides, k=6: result differs from the input';
}

done_testing;
