package Validator::Custom::CheckFunction;

use strict;
use warnings;

use Carp 'croak';

sub ascii_graphic {
  my ($vc, $value, $arg) = @_;
  
  return undef unless defined $value;
  
  my $is_valid = $value =~ /^[\x21-\x7E]+$/;
  
  return $is_valid;
}

sub number {
  my ($vc, $value, $arg) = @_;

  return undef unless defined $value;
  
  my $decimal_part_max;
  if ($arg) {
    croak "The argument of number checking function must be a hash reference"
      unless ref $arg eq 'HASH';
    
    $decimal_part_max = delete $arg->{decimal_part_max};
    
    croak "decimal_part_max must be more than 0"
      unless $decimal_part_max > 0;
    
    croak "The argument of number checking function allow only decimal_part_max"
      if keys %$arg;
  }

  if (defined $decimal_part_max) {
    if ($value =~ /^-?[0-9]+(\.[0-9]{0,$decimal_part_max})?$/) {
      return 1;
    }
    else {
      return undef;
    }
  }
  else {
    if ($value =~ /^-?[0-9]+(\.[0-9]*)?$/) {
      return 1;
    }
    else {
      return undef;
    }
  }
}

sub int {
  my ($vc, $value, $arg) = @_;

  return undef unless defined $value;
  
  my $is_valid = $value =~ /^\-?[0-9]+$/;
  
  return $is_valid;
}

sub in {
  my ($vc, $value, $arg) = @_;
  
  return undef unless defined $value;
  
  my $valid_values = $arg;
  
  croak "\"in\" check argument must be array reference"
    unless ref $valid_values eq 'ARRAY';
  
  my $match = grep { $_ eq $value } @$valid_values;
  return $match > 0 ? 1 : 0;
}

1;

=head1 NAME

Validator::Custom::CheckFunction - Checking functions
