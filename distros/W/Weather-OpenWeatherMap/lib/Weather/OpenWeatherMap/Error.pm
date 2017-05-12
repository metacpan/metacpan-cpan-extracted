package Weather::OpenWeatherMap::Error;
$Weather::OpenWeatherMap::Error::VERSION = '0.005004';
use strictures 2;
use Carp;

use Types::Standard -all;

use Moo; 

with 'StackTrace::Auto';

use overload
  bool => sub { 1 },
  '""' => sub { shift->as_string },
  fallback => 1;

has request => (
  required  => 1,
  is        => 'ro',
  isa       => InstanceOf['Weather::OpenWeatherMap::Request'],
);

has source => (
  required  => 1,
  is        => 'ro',
  isa       => sub {
    $_[0] eq 'api' || $_[0] eq 'internal' || $_[0] eq 'http'
      or die "Expected one of: api, internal, http"
  },
);

has status => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

sub as_string {
  my ($self) = @_;
  my $src = uc $self->source;
  my $msg = $self->status;
  "($src) $msg"
}

1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Error - Internal and API error objects

=head1 SYNOPSIS

  # Usually received from Weather::OpenWeatherMap

=head1 DESCRIPTION

These objects contain information on internal or backend (API) errors; they
are generally thrown by L<Weather::OpenWeatherMap> or emitted by
L<POEx::Weather::OpenWeatherMap> in response to a failed request.

These objects overload stringification (see L</as_string>).

These objects consume L<StackTrace::Auto>.

=head2 ATTRIBUTES

=head3 request

The original L<Weather::OpenWeatherMap::Request> object that caused the
error to occur.

=head3 source

The source of the error, one of: C<api>, C<internal>, C<http>

=head3 status

The error/status message string.

=head2 METHODS

=head3 as_string

Returns a stringified representation of the error in the form:
C<< (uc $err->source) $err->status >>

=head1 SEE ALSO

L<Weather::OpenWeatherMap>

L<StackTrace::Auto>

L<Devel::StackTrace>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
