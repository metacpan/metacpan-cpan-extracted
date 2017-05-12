package Weather::OpenWeatherMap::Result::Find;
$Weather::OpenWeatherMap::Result::Find::VERSION = '0.005004';
use Carp;
use strictures 2;

use List::Objects::WithUtils;
use Types::Standard      -all;
use List::Objects::Types -all;

use Weather::OpenWeatherMap::Result::Current;


use Moo; 
extends 'Weather::OpenWeatherMap::Result';


has message => (
  lazy    => 1,
  is      => 'ro',
  isa     => Str,
  builder => sub { shift->data->{message} // '' },
);
sub search_type { shift->message }


has _list => (
  init_arg => 'list',
  lazy    => 1,
  is      => 'ro',
  isa     => TypedArray[
    InstanceOf['Weather::OpenWeatherMap::Result::Current']
  ],
  coerce  => 1,
  builder => sub {
    my ($self) = @_;
    my @list = @{ $self->data->{list} || [] };
    [
      map {; 
        Weather::OpenWeatherMap::Result::Current->new(
          request => $self->request,
          json    => $self->encode_json($_),
          data    => +{%$_},
        )
      } @list
    ]
  },
);

sub count    { shift->_list->count }
sub list     { shift->_list->all }
sub as_array { array(shift->_list->all) }
sub iter {
  my ($self, $count) = @_;
  $self->_list->natatime($count || 1)
}


1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Result::Find - Location search result

=head1 SYNOPSIS

  # Normally retrieved via Weather::OpenWeatherMap

=head1 DESCRIPTION

This is a subclass of L<Weather::OpenWeatherMap::Result> containing the result
of a completed L<Weather::OpenWeatherMap::Request::Find>.

These are normally returned by a L<Weather::OpenWeatherMap> instance (or
emitted by L<POEx::Weather::OpenWeatherMap>.

=head2 ATTRIBUTES

=head3 message

The message from the OpenWeatherMap backend indicating the type of search
completed (C<accurate> or C<like>).

=head2 METHODS

=head3 as_array

The full result list, as a L<List::Objects::WithUtils::Array>.

See L</list>.

=head3 count

Returns the number of items available in the current result L</list>.

=head3 list

The full result list; each item in the list is a
L<Weather::OpenWeatherMap::Result::Current> instance:

  for my $place ($result->list) {
    my $region = $place->country;
    my $tempf  = $place->temp_f;
    # ...
  }

See L<Weather::OpenWeatherMap::Result::Current>.

The current weather returned by a Find is not quite as complete as that
returned by an actual L<Weather::OpenWeatherMap::Request::Current>. In
particular:

=over

=item *

The B<country> attribute is likely to be a two-letter region identifier, not a
full country name.

=item *

The B<sunrise> and B<sunset> attributes are unavailable.

=item *

Wind gust speed may be unavailable.

=item *

The B<station> name is unavailable.

=back

=head3 iter

Returns an iterator that, when called, returns the next
L<Weather::OpenWeatherMap::Result::Current> instance (or undef when the list
is empty):

  my $iter = $result->iter;
  while (my $place = $iter->()) {
    my $region = $place->country;
    # ...
  }

The number of items to return at a time can be specified:

  my $iter = $result->iter(3);

=head3 search_type

An alias for L</message>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
