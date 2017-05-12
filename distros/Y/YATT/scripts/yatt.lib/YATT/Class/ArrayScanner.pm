# -*- mode: perl; coding: utf-8 -*-
package YATT::Class::ArrayScanner;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(YATT::Class::Configurable);
use YATT::Fields qw(^cf_array cf_index);

sub readable {
  (my MY $path, my ($more)) = @_;
  return unless defined $path->{cf_index};
  $path->{cf_index} + ($more || 0) < @{$path->{cf_array}};
}

sub read {
  (my MY $path) = @_;
  return undef unless defined $path->{cf_index};
  my $value = $path->{cf_array}->[$path->{cf_index}];
  $path->after_read($path->{cf_index}++);
  $value;
}

sub after_read {}
sub after_next {}

sub current {
  (my MY $path, my ($offset)) = @_;
  return undef unless defined $path->{cf_index};
  $path->{cf_array}->[$path->{cf_index} + ($offset || 0)]
}

sub next {
  (my MY $path) = @_;
  return undef unless defined $path->{cf_index};
  my $val = $path->{cf_array}->[$path->{cf_index}++];
  $path->after_next;
  $val;
}

sub go_next {
  (my MY $path) = @_;
  return undef unless defined $path->{cf_index};
  $path->{cf_index}++;
  $path->after_next;
  $path;
}

sub peek {
  (my MY $path, my ($pos)) = @_;
  $path->{cf_array}[$pos];
}

1;
