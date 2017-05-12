package Weather::OpenWeatherMap::Result;
$Weather::OpenWeatherMap::Result::VERSION = '0.005004';
use Carp;
use strictures 2;

use JSON::MaybeXS ();

use Module::Runtime 'use_module';
use List::Objects::Types -all;
use Types::Standard      -all;


use Moo; 

use Storable 'freeze';

sub new_for {
  my ($class, $type) = splice @_, 0, 2;
  confess "Expected a subclass type" unless $type;
  my $subclass = join '::', $class, map ucfirst, split '::', $type;
  use_module($subclass)->new(@_)
}

sub decode_json {
  my (undef, $js) = @_;
  JSON::MaybeXS->new(utf8 => 1)->decode( $js )
}

sub encode_json {
  my (undef, $data) = @_;
  JSON::MaybeXS->new(utf8 => 1)->encode( $data )
}


has request => (
  required  => 1,
  is        => 'ro',
  writer    => 'set_request',
  isa       => InstanceOf['Weather::OpenWeatherMap::Request'],
);

has json => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

has data => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  builder   => sub {
    my ($self) = @_;
    $self->decode_json( $self->json )
  },
);

has response_code => (
  lazy      => 1,
  is        => 'ro',
  isa       => Maybe[Int],
  builder   => sub {
    my ($self) = @_;
    $self->data->{cod}
  },
);


has is_success => (
  lazy      => 1,
  is        => 'ro',
  isa       => Bool,
  builder   => sub {
    my ($self) = @_;
    ($self->response_code // '') eq '200'
  },
);

has error => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub {
    my ($self) = @_;
    return '' if $self->is_success;
    my $data = $self->data;
    my $msg = $data->{message} || 'Unknown error from backend';
    # there's only so much I can take ->
    $msg = 'Not found' if $msg =~ /Not found city/;
    $msg
  },
);


1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Result - Weather lookup result superclass

=head1 SYNOPSIS

  # Normally retrieved via Weather::OpenWeatherMap

=head1 DESCRIPTION

This is the parent class for L<Weather::OpenWeatherMap> weather results.

The L</"SEE ALSO"> section links known subclasses.

=head2 ATTRIBUTES

=head3 data

This is the decoded hash from the attached L</json> (as a
L<List::Objects::WithUtils::Hash>).

Subclasses provide more convenient accessors for retrieving desired
information.

=head3 error

The error message received from the OpenWeatherMap backend (or the empty
string if there was no error).

See also: L</is_success>, L</response_code>

=head3 is_success

Returns boolean true if the OpenWeatherMap backend returned a successful
response.

See also: L</error>, L</response_code>

=head3 json

The raw JSON this Result was created with.

=head3 response_code

The response code from OpenWeatherMap.

See also: L</is_success>, L</error>

=head3 request

The original request that was attached to this result.

=head2 METHODS

=head3 new_for

Factory method; returns a new object belonging to the appropriate subclass:

  my $result = Weather::OpenWeatherMap::Result->new_for(
    Forecast =>
      request => $orig_request,
      json    => $raw_json,
  );

=head3 decode_json

Result deserialization wrapper for use by subclasses.

=head3 encode_json

Serialization wrapper for use by subclasses.

=head1 SEE ALSO

L<http://www.openweathermap.org/api>

L<Weather::OpenWeatherMap::Result::Current>

L<Weather::OpenWeatherMap::Result::Forecast>

L<Weather::OpenWeatherMap::Result::Forecast::Block>

L<Weather::OpenWeatherMap::Result::Forecast::Day>

L<Weather::OpenWeatherMap::Result::Forecast::Hour>

L<Weather::OpenWeatherMap::Result::Find>

L<Weather::OpenWeatherMap::Request>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as perl.

=cut
