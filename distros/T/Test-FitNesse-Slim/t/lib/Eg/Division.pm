package Eg::Division;

use strict;
use warnings;

sub new {
    return bless {
        numerator   => 0,
        denominator => 0,
    }, shift;
}

sub set_numerator {
    my ($self, $numerator) = @_;
    $self->{numerator} = $numerator;
    return;
}

sub set_denominator {
    my ($self, $denominator) = @_;
    $self->{denominator} = $denominator;
    return;
}

sub quotient {
    my ($self) = @_;
    my $numerator = $self->{numerator};
    my $denominator = $self->{denominator};

    if ($denominator == 0) {
        return 'NaN' if $numerator == 0;
        return $numerator < 0 ? '-Infinity' : 'Infinity';
    }

    my $quotient = $numerator / $denominator;
    if ($quotient == int($quotient) && abs($quotient) < 10_000_000) {
        return sprintf('%.1f', $quotient);
    }
    for my $precision (1 .. 17) {
        my $formatted = sprintf("%.${precision}g", $quotient);
        next unless $formatted == $quotient;
        return $formatted =~ /[.eE]/ ? $formatted : "$formatted.0";
    }

    return sprintf('%.17g', $quotient);
}

1;
