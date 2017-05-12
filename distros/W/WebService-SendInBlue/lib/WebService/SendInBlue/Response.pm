package WebService::SendInBlue::Response;
{
  $WebService::SendInBlue::Response::VERSION = '0.005';
}

use strict;

sub new {
  my ($class, $h) = @_;

  return bless $h, $class;
}

sub code {
  my $self = shift;
  return $self->{'code'}; 
}

sub message {
  my $self = shift;
  return $self->{'message'}; 
}

sub data {
  my $self = shift;
  return $self->{'data'}; 
}

sub is_success {
  my $self = shift;
  $self->code eq 'success';
}

1;
