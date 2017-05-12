package Test::Easy::equivalence;
use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  return bless +{
    test => $args{test},
    explain => $args{explain} || sub { '' },
    raw => $args{raw} || [],
  }, $class;
}

sub check_value {
  my ($self, $got) = @_;
  return $self->{test}->($got);
}

sub explain {
  my ($self, $got) = @_;
  return $self->{explain}->($got, $self->{raw});
}

1;
