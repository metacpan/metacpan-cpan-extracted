package Validator::Custom::FilterFunction;

use strict;
use warnings;

use Carp 'croak';

sub remove_blank {
  my ($vc, $values, $arg) = @_;
  
  croak "\"remove_blank filter value must be array reference"
    unless ref $values eq 'ARRAY';
  
  $values = [grep { defined $_ && CORE::length $_} @$values];
  
  return $values;
}

sub trim {
  my ($vc, $value, $arg) = @_;
  
  return undef unless defined $value;

  $value =~ s/^\s*(.*?)\s*$/$1/ms;

  return $value;
}

1;

=head1 NAME

Validator::Custom::FilterFunction - Filtering functions
