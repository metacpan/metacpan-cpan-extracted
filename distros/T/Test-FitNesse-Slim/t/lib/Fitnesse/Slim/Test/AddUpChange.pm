package Fitnesse::Slim::Test::AddUpChange;

use strict;
use warnings;

my %COIN_VALUES = (
    '1c'  => 1,
    '5c'  => 5,
    '10c' => 10,
    '25c' => 25,
    '50c' => 50,
    '$1'  => 100,
);

sub new {
    my ($class) = @_;
    return bless { total_cents => 0 }, $class;
}

sub reset {
    my ($self) = @_;
    $self->{total_cents} = 0;
    return;
}

sub set {
    my ($self, $coin, $amount) = @_;
    die "java.lang.IllegalArgumentException: Unknown coin type $coin"
        unless exists $COIN_VALUES{$coin};

    $self->{total_cents} += $amount * $COIN_VALUES{$coin};
    return;
}

sub get {
    my ($self, $requested_value) = @_;
    return sprintf('%.2f', $self->{total_cents} / 100)
        if defined($requested_value) && $requested_value eq '$ total';
    return "$self->{total_cents}";
}

1;
