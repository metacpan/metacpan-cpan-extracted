package WebSource::Filter::distance;
use strict;
use Carp;

use WebSource::Filter;
our @ISA = ('WebSource::Filter');

=head1 NAME

WebSource::Filter::script - Use a script for filtering

=head1 DESCRIPTION

Each time an object passes thru this filter a meta-information named distance
is incremented by 1. Once this meta-information has reached the maximum
the item is filtered.

=head1 SYNOPSIS

B<In wsd file...>

<ws:filter name="somename" type="distance" forward-to"somemodules">
  <parameters>
    <param name="maximum" value="<maxvalue>" />
  </parameters>
</ws:filter>


=head1 METHODS

=cut



sub new {
  my $class = shift;
  my %params = @_;
  my $self = bless \%params, $class;
  $self->SUPER::_init_;

  $self->{maximum} or $self->{maximum} = 5;  
  $self->log(2,"Maximum set to ",$self->{maximum}); 
  return $self;
}

sub keep {
  my $self = shift;
  my $env = shift;
  $self->log(6,"Distance was '",$env->{distance},"'");
  if($env->{distance}) {
    $env->{distance} += 1;
  } else {
    $env->{distance} = 1;
  }
  $self->log(6,"Distance is now '",$env->{distance},"'");
  $self->log(5,"Distance updated env is now : ",$env->as_string);
  return (! $self->{maximum}) || ($env->{distance} <= $self->{maximum}); 
}

=head1 SEE ALSO

WebSource

=cut

1;

