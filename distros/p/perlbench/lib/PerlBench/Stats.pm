package PerlBench::Stats;

use strict;

use base 'Exporter';
our @EXPORT_OK = qw(calc_stats);

sub calc_stats {
    my($samples, $hash) = @_;
    $hash ||= {};
    my @t = sort {$a <=> $b} @$samples;
    my $n = @t;
    return undef unless $n;

    my $sum = 0;
    my $sum2 = 0;
    for (@t) {
	$sum += $_;
	$sum2 += $_ * $_;
    }

    $hash->{avg} = $sum / $n;
    $hash->{stddev} = sqrt(($sum2 - ($sum * $sum)/$n) / $n);

    $hash->{min} = $t[0];
    $hash->{med} = ($n % 2) ? $t[$n/2] : (($t[$n/2-1] + $t[$n/2])/2);
    $hash->{max} = $t[-1];
    $hash->{n} = $n;

    return $hash;
}

1;
