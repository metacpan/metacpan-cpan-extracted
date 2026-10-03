use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use UshuffleTest;

use Ushuffle qw(shuffle);

my $seq = 'ACACGUAGAUGGGGA';

for my $k (1 .. 5) {
    my $out = shuffle($seq, $k);
    is length $out, length $seq, "k=$k: length is kept";
    is klets($out, $k), klets($seq, $k), "k=$k: $k-let counts are kept";
    ok same_klets($seq, $out, $k), "k=$k: all lower orders are kept as well";
}

is Ushuffle::shuffle($seq, 2) =~ tr/ACGU//, length $seq,
    'callable by its full name';

# random sequences over several alphabets, lengths and let sizes
srand 1;
for my $alphabet ('ACGU', 'AC', 'ACDEFGHIKLMNPQRSTVWY', "A\xE9\xFF", 'aAcC', "A \n\t,=") {
    my ($bad_counts, $bad_ends) = (0, 0);
    for (1 .. 500) {
        my $len = 1 + int rand 80;
        my $k   = 1 + int rand 7;
        my $in  = random_sequence($len, $alphabet);
        my $out = shuffle($in, $k);
        $bad_counts++ unless same_klets($in, $out, $k);

        # the first and the last k-1 letters stay where they are
        my $fixed = $k - 1 < $len ? $k - 1 : $len;
        $bad_ends++
            if substr($out, 0, $fixed) ne substr($in, 0, $fixed)
            or substr($out, $len - $fixed) ne substr($in, $len - $fixed);
    }
    my $name = sprintf '%d-letter alphabet', length $alphabet;
    is $bad_counts, 0, "$name: random sequences keep their k-let counts";
    is $bad_ends,   0, "$name: random sequences keep their first and last k-1 letters";
}

# every let size from 1 up to beyond the length of one sequence
{
    my $in  = random_sequence(40, 'ACGU');
    my @bad = grep { !same_klets($in, shuffle($in, $_), $_) } 1 .. 45;
    is "@bad", '', 'all let sizes from 1 to beyond the length';
}

{
    my $long = random_sequence(200, 'ACGU');
    my %seen;
    $seen{ shuffle($long, 2) }++ for 1 .. 20;
    cmp_ok scalar keys %seen, '>', 1, 'repeated calls give different shuffles';
}

# inputs with exactly one valid shuffle
is shuffle($seq, length $seq), $seq,        'k equal to the length returns a copy';
is shuffle($seq, 1000),        $seq,        'k above the length returns a copy';
is shuffle($seq, 2**40),       $seq,        'k beyond the range of a C int';
is shuffle('',   2),           '',          'empty sequence';
is shuffle('A',  1),           'A',         'single letter, k=1';
is shuffle('A',  2),           'A',         'single letter, k=2';
is shuffle('AC', 1) =~ tr/AC//, 2,          'two letters, k=1';
is shuffle('AC', 2),           'AC',        'two letters, k=2';
is shuffle('AAAAAAAA', 1),     'AAAAAAAA',  'homopolymer, k=1';
is shuffle('AAAAAAAA', 3),     'AAAAAAAA',  'homopolymer, k=3';
is shuffle('ACGU',     2),     'ACGU',      'all dinucleotides different';
is shuffle('ACACACAC', 2),     'ACACACAC',  'dinucleotide repeat';
is shuffle('ABAB',     3),     'ABAB',      'k=3 keeps the first two letters';
is shuffle(12345, 5),          '12345',     'numbers are treated as strings';

# upper and lower case are different letters
{
    my $out = shuffle('aAaAaAAAaa', 1);
    is $out =~ tr/a//, 5, 'lower case letters are kept';
    is $out =~ tr/A//, 5, 'upper case letters are kept';
}

# what is returned
{
    my @list = shuffle($seq, 2);
    is scalar @list, 1, 'one value in list context';

    my $first  = shuffle($seq, 2);
    my $copy   = $first;
    my $second = shuffle($seq, 2);
    is $first, $copy, 'an earlier result is not overwritten by a later call';
    $second .= 'x';
    substr($second, 0, 1) = 'y';
    is $first, $copy, '... nor by changing the later result';
    ok !utf8::is_utf8($first), 'the result is a byte string';
    is length(shuffle($seq, 2) . 'tail'), length($seq) + 4,
        'the result can be used in an expression';
}

# the input, and scalars sharing its buffer, must be left alone
{
    my $in     = 'ACGUUGCAACGGUUAC';
    my $shared = $in;
    my $out    = shuffle($in, 2);
    is $in,     'ACGUUGCAACGGUUAC', 'input is not modified';
    is $shared, 'ACGUUGCAACGGUUAC', 'a copy of the input is not modified';

    for my $round (1 .. 3) {
        my $literal = 'ACGUUGCAACGGUUAC';
        is $literal, $in, "round $round: a string literal is intact";
        $literal = shuffle($literal, 2);
        ok same_klets($in, $literal, 2),
            "round $round: assigning the result to its own input";
    }
}

done_testing;
