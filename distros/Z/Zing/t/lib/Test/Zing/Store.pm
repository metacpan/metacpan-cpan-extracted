package Test::Zing::Store;

use 5.014;

use strict;
use warnings;

use parent 'Zing::Store';

# VERSION

our $DATA = {};

# METHODS

sub drop {
  my ($self, $key) = @_;
  return int(!!delete $DATA->{$key});
}

sub dump {
  my ($self, $val) = @_;
  return $val;
}

sub keys {
  my ($self, @key) = @_;
  my $re = join('|', $self->term(@key), $self->term(@key, '.*'));
  return [grep /$re/, keys %$DATA];
}

sub load {
  my ($self, $val) = @_;
  return $val;
}

sub lpull {
  my ($self, $key) = @_;
  my $get = shift @{$DATA->{$key}} if $DATA->{$key};
  return $get ? $self->load($get) : $get;
}

sub lpush {
  my ($self, $key, $val) = @_;
  my $set = $self->dump($val);
  return unshift @{$DATA->{$key}}, $set;
}

sub recv {
  my ($self, $key) = @_;
  my $get = $DATA->{$key};
  return $get ? $self->load($get) : $get;
}

sub rpull {
  my ($self, $key) = @_;
  my $get = pop @{$DATA->{$key}} if $DATA->{$key};
  return $get ? $self->load($get) : $get;
}

sub rpush {
  my ($self, $key, $val) = @_;
  my $set = $self->dump($val);
  return push @{$DATA->{$key}}, $set;
}

sub send {
  my ($self, $key, $val) = @_;
  my $set = $self->dump($val);
  $DATA->{$key} = $set;
  return 'OK';
}

sub size {
  my ($self, $key) = @_;
  return $DATA->{$key} ? scalar(@{$DATA->{$key}}) : 0;
}

sub slot {
  my ($self, $key, $pos) = @_;
  my $get = $DATA->{$key}->[$pos];
  return $get ? $self->load($get) : $get;
}

sub test {
  my ($self, $key) = @_;
  return int exists $DATA->{$key};
}

1;
