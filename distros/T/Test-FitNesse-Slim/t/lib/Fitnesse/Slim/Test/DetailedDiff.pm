package Fitnesse::Slim::Test::DetailedDiff;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {
        actual_string => undef,
        actual_int => 0,
        actual_double => 0,
        actual_symbol => undef,
    }, $class;
}

sub set_actual_string { $_[0]->{actual_string} = $_[1]; return }
sub expected_string  { $_[0]->{actual_string} }
sub set_actual_int   { $_[0]->{actual_int} = $_[1]; return }
sub expected_int     { $_[0]->{actual_int} }

sub set_actual_double {
    $_[0]->{actual_double} = 0 + $_[1];
    return;
}

sub expected_double {
    my ($self) = @_;
    my $value = sprintf('%.15g', $self->{actual_double});
    $value .= '.0' if $value !~ /[.eE]/;
    return $value;
}

sub set_actual_symbol { $_[0]->{actual_symbol} = $_[1]; return }
sub expected_symbol   { $_[0]->{actual_symbol} }
sub echo              { $_[1] }

1;
