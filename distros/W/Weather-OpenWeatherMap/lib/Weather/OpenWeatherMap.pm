package Weather::OpenWeatherMap;
$Weather::OpenWeatherMap::VERSION = '0.005004';
use strictures 2;
use Carp;

use LWP::UserAgent;

use Types::Standard -all;


use Weather::OpenWeatherMap::Cache;
use Weather::OpenWeatherMap::Error;


# Full require list to make Storable retrievals comfortable:
use Weather::OpenWeatherMap::Request;
require Weather::OpenWeatherMap::Request::Current;
require Weather::OpenWeatherMap::Request::Forecast;

use Weather::OpenWeatherMap::Result;
require Weather::OpenWeatherMap::Result::Current;
require Weather::OpenWeatherMap::Result::Forecast;

use Moo; 

=pod

=for Pod::Coverage has_api_key

=cut

has api_key => (
  is        => 'ro',
  isa       => Str,
  predicate => 1,
  writer    => 'set_api_key',
  builder   => sub {
    carp "No api_key specified, requests will likely fail!";
    '' 
  },
);

has cache => (
  lazy      => 1,
  is        => 'ro',
  isa       => Bool,
  builder   => sub { 0 },
);

has cache_dir => (
  lazy      => 1,
  is        => 'ro',
  isa       => Maybe[Str],
  builder   => sub { undef },
);

has cache_expiry => (
  lazy      => 1,
  is        => 'ro',
  isa       => Maybe[StrictNum],
  builder   => sub { undef },
);

has _cache => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['Weather::OpenWeatherMap::Cache'],
  builder   => sub {
    my ($self) = @_;
    Weather::OpenWeatherMap::Cache->new(
      ( $self->cache_dir ?    (dir => $self->cache_dir)       : () ),
      ( $self->cache_expiry ? (expiry => $self->cache_expiry) : () ),
    )
  },
);


has ua => (
  is        => 'ro',
  isa       => InstanceOf['LWP::UserAgent'],
  builder   => sub { LWP::UserAgent->new(timeout => 60) },
);


sub get_weather {
  my ($self, %args) = @_;

  croak "Missing 'location =>' in query" unless $args{location};

  my $type = 
      delete $args{forecast} ? 'Forecast' 
    : delete $args{find}     ? 'Find'
    : 'Current';

  my $my_request = Weather::OpenWeatherMap::Request->new_for(
    $type => 
      (
        $self->has_api_key && length $self->api_key ?
          ( api_key => $self->api_key ) : ()
      ),
      %args
  );

  my $result;

  if ( $self->cache && (my $cached = $self->_cache->retrieve($my_request)) ) {
    $result = $cached->object
  } else {
    my $http_response = $self->ua->request( $my_request->http_request );

    unless ($http_response->is_success) {
      die Weather::OpenWeatherMap::Error->new(
        request => $my_request,
        source  => 'http',
        status  => $http_response->status_line,
      );
    }

    $result = Weather::OpenWeatherMap::Result->new_for(
      $type =>
        request => $my_request,
        json    => $http_response->content,
    );
  }

  unless ($result->is_success) {
    die Weather::OpenWeatherMap::Error->new(
      request => $my_request,
      source  => 'api',
      status  => $result->error,
    )
  }

  $self->_cache->cache($result) if $self->cache;

  $result
}


1;

=pod

=head1 NAME

Weather::OpenWeatherMap - Interface to the OpenWeatherMap API

=head1 SYNOPSIS

  use Weather::OpenWeatherMap;

  my $api_key = 'foo';

  my $wx = Weather::OpenWeatherMap->new(
    api_key => $api_key,
  );

  # Current conditions:
  # (see Weather::OpenWeatherMap::Result::Current)
  my $current = $wx->get_weather(
    location => 'Manchester, NH',
  );
  my $tempf = $current->temp_f;
  my $wind  = $current->wind_speed_mph;

  # Daily forecast conditions:
  # (see Weather::OpenWeatherMap::Result::Forecast)
  my $forecast = $wx->get_weather(
    location => 'Manchester, NH',
    forecast => 1,
    days     => 3,
  );
  for my $day ($forecast->list) {
    my $date    = $day->dt->mdy;
    my $temp_lo = $day->temp_min_f,
    my $temp_hi = $day->temp_max_f,
    # (see Weather::OpenWeatherMap::Result::Forecast::Day)
  }

  # Hourly (3-hr blocks) forecast conditions:
  my $forecast = $wx->get_weather(
    location => 'Manchester, NH',
    forecast => 1,
    hourly   => 1,
    days     => 3,
  );
  for my $block ($forecast->list) {
    my $time = $block->dt_txt;
    my $temp = $block->temp;
    # (see Weather::OpenWeatherMap::Result::Forecast::Hour)
  }

  # Find a city:
  # (see Weather::OpenWeatherMap::Result::Find)
  my $search = $wx->get_weather(
    location => 'Manchester',
    find     => 1,
    max      => 5,
  );
  for my $place ($search->list) {
    my $region = $place->country;
    # ...
  }

=head1 DESCRIPTION

An object-oriented interface to retrieving weather conditions & forecasts from
B<OpenWeatherMap> (L<http://www.openweathermap.org/>) for a given city,
latitude/longitude, or OpenWeatherMap city code.

This module provides a simple blocking (L<LWP::UserAgent>) interface to
weather retrieval; if you have an event loop handy, the included
L<Weather::OpenWeatherMap::Request> & L<Weather::OpenWeatherMap::Result>
classes can be used to create appropriate L<HTTP::Request> instances and parse
responses from non-blocking HTTP clients.

See L<POEx::Weather::OpenWeatherMap> for a non-blocking implementation using
the L<POE> ecosystem.

=head2 ATTRIBUTES

=head3 api_key

Your L<OpenWeatherMap|http://www.openweathermap.org/> API key.

(See L<http://www.openweathermap.org/api> to register for free.)

C<api_key> can be set after object construction via B<set_api_key>; if the key
is invalid, requests will likely fail with C<< 401 Unauthorized >> errors.

=head3 cache

A boolean value indicating whether successful results should be cached to
disk via L<Weather::OpenWeatherMap::Cache>.

Defaults to false. This may change in a future release.

=head3 cache_dir

The directory in which cache files are saved. The default may be fine; see
L<Weather::OpenWeatherMap::Cache>.

=head3 cache_expiry

The duration (in seconds) for which cache files are considered valid; see
L<Weather::OpenWeatherMap::Cache>.

=head3 ua

The L<LWP::UserAgent> instance used to issue HTTP requests; can be used to
control LWP options:

  my $wx = Weather::OpenWeatherMap->new(
    api_key => $my_api_key,
    ua => LWP::UserAgent->new(%lwp_opts),  
  );

=head2 METHODS

=head3 get_weather

  $wx->get_weather(
    # 'location =>' is mandatory.
    #  These are all valid location strings:
    #  By name:
    #   'Manchester, NH'
    #   'London, UK'
    #  By OpenWeatherMap city code:
    #   5089178
    #  By latitude/longitude:
    #   'lat 42, long -71'
    location => 'Manchester, NH',

    # Set 'forecast => 1' to get the forecast,
    # omit or set to false for current weather:
    forecast => 1,

    # If 'forecast' is true, you can ask for an hourly (rather than daily)
    # forecast report:
    hourly => 1,

    # If 'forecast' is true, you can specify the number of days to fetch
    # (up to 16 for daily reports, 5 for hourly reports):
    days => 3,

    # Optional tag for identifying the response to this request:
    tag  => 'foo',
  );

Request a weather report (in the form of a L<Weather::OpenWeatherMap::Result>
object) for the given C<< location => >>.

The location can be a 'City, State' or 'City, Country' string, an
L<OpenWeatherMap|http://www.openweathermap.org/> city code, or a 'lat X, long
Y' string.

Requests the current weather by default (see
L<Weather::OpenWeatherMap::Request::Current> and
L<Weather::OpenWeatherMap::Result::Current>).

If passed C<< forecast => 1 >>, requests a weather forecast (see
L<Weather::OpenWeatherMap::Request::Forecast> and
L<Weather::OpenWeatherMap::Result::Forecast>), in which case C<< days =>
$count >> and/or C<< hourly => $bool >> can be specified.

If passed C<< find => 1 >>, requests search results for a given location name
or latitude & longitude; see L<Weather::OpenWeatherMap::Request::Find> and
L<Weather::OpenWeatherMap::Result::Find>.

Any extra arguments are passed to the constructor for the appropriate Request
subclass; see L<Weather::OpenWeatherMap::Request>.

=head1 SEE ALSO

L<Weather::OpenWeatherMap::Result>

L<POEx::Weather::OpenWeatherMap>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
