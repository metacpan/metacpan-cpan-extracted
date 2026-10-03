package UshuffleTest;

# Helpers shared by the test files: an independent description of what a
# valid shuffle is, against which the library is checked.

use strict;
use warnings;

require Exporter;
our @ISA    = ('Exporter');
our @EXPORT = qw(klets same_klets random_sequence all_shuffles chi2_limit);

# The k-let counts of a sequence as one comparable string.
sub klets {
    my ($seq, $k) = @_;
    my %n;
    $n{ substr $seq, $_, $k }++ for 0 .. length($seq) - $k;
    return join ',', map { unpack('H*', $_) . "=$n{$_}" } sort keys %n;
}

# True if $out is as long as $in and has the same j-let counts for every
# j up to $k. A shuffle keeps the lower orders too, because it keeps the
# first k-1 letters in place.
sub same_klets {
    my ($in, $out, $k) = @_;
    return 0 if length $in != length $out;
    $k = length $in if $k > length $in;
    for my $j (1 .. $k) {
        return 0 if klets($in, $j) ne klets($out, $j);
    }
    return 1;
}

# A random sequence; call srand first for a reproducible one.
sub random_sequence {
    my ($len, $alphabet) = @_;
    my @letters = split //, $alphabet;
    return join '', map { $letters[ rand @letters ] } 1 .. $len;
}

# Every distinct sequence that is a valid shuffle of $seq for let size $k,
# found by brute force: build all sequences that use up the k-lets of $seq,
# starting from any (k-1)-let, and keep those passing same_klets.
sub all_shuffles {
    my ($seq, $k) = @_;
    my $len = length $seq;
    return ($seq) if $k >= $len;

    my (%left, %start, %letter);
    $left{ substr $seq, $_, $k }++ for 0 .. $len - $k;
    $start{ substr $seq, $_, $k - 1 }++ for 0 .. $len - $k + 1;
    $letter{$_}++ for split //, $seq;
    my @letters = sort keys %letter;

    my @found;
    my $extend;
    $extend = sub {
        my ($prefix) = @_;
        if (length $prefix == $len) {
            push @found, $prefix;
            return;
        }
        for my $c (@letters) {
            my $let = substr($prefix, length($prefix) - $k + 1) . $c;
            next unless $left{$let};
            $left{$let}--;
            $extend->($prefix . $c);
            $left{$let}++;
        }
    };
    $extend->($_) for sort keys %start;
    undef $extend;

    return grep { same_klets($seq, $_, $k) } @found;
}

# Upper limit for a chi-square statistic with $df degrees of freedom that a
# correct sampler exceeds with a probability of about 1e-9 (Wilson-Hilferty
# approximation at six standard deviations).
sub chi2_limit {
    my ($df) = @_;
    my $v = 2 / (9 * $df);
    return $df * (1 - $v + 6 * sqrt $v)**3;
}

1;
