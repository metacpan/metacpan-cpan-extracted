package Weather::OWM;

use 5.008;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use Time::Local;

=head1 NAME

Weather::OWM - Perl client for the OpenWeatherMap (OWM) API

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

  use Weather::OWM;
  use strict;
  use v5.10;

  my $owm = Weather::OWM->new(key => 'Your API key');

  ### Using the free endpoints of the "classic" Weather API 2.5:
 
  # Get current weather for the Stonehenge area using coordinates...
  my %re = $owm->get_weather(lat => 51.18, lon => -1.83);

  # ...and print temperature, humidity, wind speed
  say "$re{main}->{temp}C $re{main}->{humidity}% $re{wind}->{speed}m/s"
      unless $re{error};

  # Get 3h/5d forecast for London, UK...
  %re = $owm->get_weather(product => 'forecast', loc => 'London,UK');

  # ...and print the temperature for every three hours over the next 5 days
  say scalar(localtime($_->{dt}))." $_->{main}->{temp}C" for @{$re{list}};

  ### Using the newer One Call 3.0 API:

  # Get current weather and min/h/day forecast for Punxsutawney, PA...
  %re = $owm->one_call(city => 'Punxsutawney,PA,US', units => 'imperial');

  # ...print current temperature, humidity, wind speed...
  say "$re{current}->{temp}F $re{current}->{humidity}% $re{current}->{wind_speed}mph"
      unless $re{error};
  
  # ...and print the temperature for every hour over the next 2 days
  say "$_->{temp}F" for @{$re{hourly}};

  ### Using the History API 2.5:

  # Get the historical weather for the first 72 hours of 2023 at Greenwich, UK...
  my %report = $owm->get_history(
      product => 'hourly',
      loc     => 'Greenwich,UK',
      start   => '2023-01-01 00:00:00',
      cnt     => '72'
  );

  # ...and print the temperatures next to the date/time
  say scalar(localtime($_->{dt}))." $_->{main}->{temp}C" for @{$re{list}};

  ### Using the Geocoder API:

  # Fetch Portland, Maine from the Geocoder API...
  my @locations = $owm->geo(city => 'Portland,ME,US');

  # ...and print the latitude,longitude
  say "$locations[0]->{lat},$locations[0]->{lon}";

  # Get the top 5 cities named "Portland" in the US...
  @locations = $owm->geo(city => 'Portland,US', limit=>5);

  # ...and print their state and coordinates.
  say "$_->{state} $_->{lat},$_->{lon}" for @locations;

  # Perform reverse geocoding of coordinates 51.51 North, 0.12 West...
  @locations = $owm->geo(lat=>51.51, lon=>-0.12);

  # ...and print the location name, country
  say "$locations[0]->{name}, $locations[0]->{country}";

=head1 DESCRIPTION

L<Weather::OWM> is a lightweight Perl client supporting most OpenWeatherMap (OWM) APIs,
including the latest One Call v3.0.

There is an easy-to-use object oriented interface that can return the data in hashes.
There are virtually no dependencies, except L<LWP::UserAgent> for the requests, and
optionally L<JSON> or L<XML::Simple> if you want to decode JSON (most common) or XML data.

Current OWM API support:

=over 4

=item * OneCall API 3.0 for current weather, forecast and weather history.

=item * Weather API 2.5 including free (current weather, 3h/5d forecast) and paid forecasts.

=item * Historical APIs 2.5 (history, statistical, accumulated).

=item * Geocoding API 1.0 for direct/reverse geocoding.

=back

Please see L<the official OWM website|https://openweathermap.org/api> for extensive
documentation. Note that even the free APIs require L<signing up|https://home.openweathermap.org/users/sign_up>
for an API key.

This module belongs to a family of weather modules (along with L<Weather::Astro7Timer>
and L<Weather::WeatherKit>) created to serve the apps L<Xasteria|https://astro.ecuadors.net/xasteria/>
and L<Polar Scope Align|https://astro.ecuadors.net/polar-scope-align/>, but if your
service requires some extra functionality, feel free to contact the author about adding it.

=head1 CONSTRUCTOR

=head2 C<new>

    my $owm = Weather::OWM->new(
        key     => $api_key,             #required
        timeout => $timeout_sec?,
        agent   => $user_agent_string?,
        ua      => $lwp_ua?,
        lang    => $lang?,
        units   => $units?,
        error   => $die_or_return?,
        debug   => $debug?,
        scheme  => $url_scheme?
    );

Creates a Weather::OWM object.

Required parameters:

=over 4

=item * C<key> : The API key is required for both free and paid APIs. For the former,
you can L<sign up|https://home.openweathermap.org/users/sign_up> for a free account.

=back

Optional parameters:

=over 4

=item * C<timeout> : Timeout for requests in secs. Default: C<30>.

=item * C<agent> : Customize the user agent string.

=item * C<ua> : Pass your own L<LWP::UserAgent> to customise further. Will override C<agent>.

=item * C<lang> : Set language (two letter language code) for requests. You can override per API call. Default: C<en>.

=item * C<units> : Set units (standard, metric, imperial). You can override per API call. Default: C<metric>. Available options:

=over 4

=item * C<standard> : Temperature in Kelvin. Wind speed in metres/sec.

=item * C<metric> : Temperature in Celsius. Wind speed in metres/sec.

=item * C<imperial> : Temperature in Fahrenheit. Wind speed in mph.

=back

=item * C<error> : If there is an error response with the main methods, you have the options to C<die> or C<return> it. You can override per API call. Default: C<return>.

=item * C<debug> : If debug mode is enabled, API URLs accessed are printed in STDERR. Default: C<false>.

=item * C<scheme> : You can use C<http> as an option if you have trouble building https support for LWP in your system. Default: C<https>.

=back

=head1 MAIN METHODS

The main methods will return a string containing the JSON (or XML etc where specified),
except in the array context (C<< my %hash = $owm->method >>), where L<JSON> (or similar)
will be used to conveniently decode it to a Perl hash.

If the request is not successful, by default an C<ERROR: status_line> will be returned
in scalar context or C<(error => HTTP::Response)> in array context.
If the constructor was set with an C<error> equal to C<die>, then it will die throwing
the C<< HTTP::Response->status_line >>.

For custom error handling, see the alternative methods.

=head2 C<one_call>

One Call 3.0 API

    my $report = $owm->one_call(
        product => $product,    # Can be: forecast, historical, daily
        lat     => $lat,        # Required unless city/zip specified
        lon     => $lon,        # Required unless city/zip specified
        city    => $city?,      # City,country (via Geocoder API)
        zip     => $zip?,       # Zip/postcode,country (via Geocoder API)
        date    => $date?,      # Date or unix timestamp: required for daily/historical
    );

    my %report = $owm->one_call( ... );

Fetches a One Call API v3.0 response for the desired location. The One Call API
offers 3 products, which differ in some options as listed below. C<lang>, C<error>
and C<units> options specified in the constructor can be overridden on each call.

For an explanation to the returned data, refer to the L<official API documentation|https://openweathermap.org/api/one-call-3>.

Parameters common to all products:

=over 4


=item * C<lat> : Latitude (-90 to 90). South is negative.

=item * C<lon> : Longitude (-180 to 180). West is negative.

Latitude/Longitude are normally required.
As a convenience, you can specify a city name or a zip/post code instead:

=item * C<city> : Expects C<city name,country code> or C<city name,state code,US>,
where C<country code> is ISO 3166.

=item * C<zip> : Expects C<zip/post code,country code>, where C<country code> is ISO 3166.

Note that to avoid issues with ambiguity of city names etc you can use the
Geocoder API manually.

=back

=head4 One Call API products

Three call types/products to use listed below, along with any custom parameters they support.
If no product is specified, C<forecast> is used.

=over 4

=item * C<forecast> : B<Current weather and forecasts>: Provides a minute forecast for 1 hour, hourly for 48 hours and daily for 8 days.
Optional parameter:

=over 4

=item * C<exclude> : Exclude data from the API response (to reduce size). It expects a comma-delimited list with any combination of the possible values:
C<current>,C<minutely>,C<hourly>,C<daily>,C<alerts>

=back

=item * C<historical> : B<Weather data for any timestamp>: 40+ year historical archive and 4 days ahead forecast.
Required parameter:

=over 4

=item * C<date> : Unix timestamp for start of the data. Data is available from 1979-01-01.
For convenience, C<date> can be specified instead in iso format C<YYYY-MM-DD HH:mm:ss>
for your local time (or C<YYYY-MM-DD HH:mm:ssZ> for UTC).

=back

=item * C<daily> : B<Daily aggregation>: 40+ year weather archive and 1.5 years ahead forecast.
Required parameter:

=over 4

=item * C<date> : Date of request in the format C<YYYY-MM-DD>.
For convenience, the timestamp/date formats of the C<historical> product can be used (will be truncated to just the plain date).

=back

=back 

=head2 C<get_weather>

Weather API 2.5

    my $report = $owm->get_weather(
        product => $product,    # Can be: current, forecast, hourly, daily, climate
        lat     => $lat,        # Required unless loc/zip/city_id specified
        lon     => $lon,        # Required unless loc/zip/city_id specified
        loc     => $location?,  # Named location (deprecated)
        zip     => $zip?,       # Zip/postcode (deprecated)
        city_id => $city_id?,   # city_id (deprecated)
        mode    => $mode?,      # output mode - default: json
    );

    my %report = $owm->get_weather( ... );

Fetches a weather API v2.5 response for the desired location. The weather API has
several products available (some free, others requiring paid subscription), some have
special arguments as listed below. C<lang>, C<error> and C<units> options specified
in the constructor can be overridden on each call.

For an explanation to the returned data, refer to the L<official API documentation|https://openweathermap.org/api>
or see below in the products list the links for each endpoint.

Parameters common to all products:

=over 4
 
=item * C<lat> : Latitude (-90 to 90). South is negative. Required unless loc/zip/city_id specified.

=item * C<lon> : Longitude (-180 to 180). West is negative. Required unless loc/zip/city_id specified.

=item * C<loc> : Deprecated (lat/lon recommended - see Geocoder API). Location given either as a C<city name>
or C<city name,country code> or C<city name,state code,US>.

=item * C<zip> : Deprecated (lat/lon recommended - see Geocoder API). Expects C<zip/post code> (US) or C<zip/post code,country code>.

=item * C<city_id> : Deprecated (lat/lon recommended - see Geocoder API). City id from list L<here|https://bulk.openweathermap.org/sample/city.list.json.gz>.

=item * C<mode> : Output mode. Default is json C<json>, C<xml> is the supported alternative (unless otherwise specified).

=back

=head4 API products

There are several API endpoints which are selected via C<product> (two of them accessible with a free key).
They are listed below, along with any custom parameters they support. If no product is provided, C<current> is used.

=over 4

=item * C<current> : B<Current Weather Data> (free product). For response details see L<official API doc|https://openweathermap.org/current>.

=over 4

=item * C<mode> : C<xml> and C<html> are supported as alternatives. (Optional)

=back

=item * C<forecast> : B<5 Day / 3 Hour Forecast> (free product). For response details see L<official API doc|https://openweathermap.org/forecast5>.

=over 4

=item * C<cnt> : Limit the number of timestamps returned. (Optional)

=back

=item * C<hourly> : B<Hourly Forecast (4 days)>. For response details see L<official API doc|https://openweathermap.org/api/hourly-forecast>.

=over 4

=item * C<cnt> : Limit the number of timestamps returned. (Optional)

=back

=item * C<daily> : B<Daily Forecast (16 days)>. For response details see L<official API doc|https://openweathermap.org/forecast16>.

=over 4

=item * C<cnt> : Number of days (1 to 16) to be returned. (Optional)

=back

=item * C<climate> : B<Climatic Forecast (30 days)>. For response details see L<official API doc|https://openweathermap.org/api/forecast30>.

=over 4

=item * C<cnt> : Number of days (1 to 30) to be returned. (Optional)

=back

=back

=head2 C<get_history>

History API 2.5

    my $report = $owm->get_history(
        product => $product,    # Can be: hourly, year, month, day, temp, precip
        lat     => $lat,        # Required unless loc/zip/city_id specified
        lon     => $lon,        # Required unless loc/zip/city_id specified
        loc     => $location?,  # Named location (deprecated)
        zip     => $zip?,       # Zip/postcode (deprecated)
        city_id => $city_id?,   # city_id (deprecated)
    );

    my %report = $owm->get_history( ... );

Fetches a historical weather API v2.5 response for the desired location. The weather API has
several products available, some have special arguments as listed below. C<lang>, C<error>
and C<units> options specified in the constructor can be overridden on each call.

For an explanation to the returned data, refer to the L<official API documentation|https://openweathermap.org/api>
or see below in the products list the links for each endpoint.

Parameters common to all products:

=over 4
 
=item * C<lat> : Latitude (-90 to 90). South is negative. Required unless loc/zip/city_id specified.

=item * C<lon> : Longitude (-180 to 180). West is negative. Required unless loc/zip/city_id specified.

=item * C<loc> : Deprecated (lat/lon recommended - see Geocoder API). Location given either as a C<city name>
or C<city name,country code> or C<city name,state code,US>.

=item * C<zip> : Deprecated (lat/lon recommended - see Geocoder API). Expects C<zip/post code> (US) or C<zip/post code,country code>.

=item * C<city_id> : Deprecated (lat/lon recommended - see Geocoder API). City id from list L<here|https://bulk.openweathermap.org/sample/city.list.json.gz>.

=back

=head4 API products

There are several API endpoints which are selected via C<product>.
They are listed below, along with any custom parameters they support.
If none is specified, C<hourly> is used.

=over 4

=item * C<hourly> : B<Hourly Historical Data>. For response details see L<official API doc|https://openweathermap.org/history>.
Parameters:

=over 4

=item * C<start> : (required) Start date. Unix timestamp (or iso date).

=item * C<end> : (required unless C<cnt> specified) End date. Unix timestamp (or iso date).

=item * C<cnt> : (required unless C<end> specified) Number of timestamps returned (used instead of C<end>).

=back

=item * C<year> : B<Statistical Climate Data: Yearly aggregation>. Returns statistical climate indicators for the entire year. For response details see L<official API doc|https://openweathermap.org/api/statistics-api>.

=item * C<month> : B<Statistical Climate Data: Monthly aggregation>. Returns statistical climate indicators for a specific month of the year. For response details see L<official API doc|https://openweathermap.org/api/statistics-api>.
Parameters:

=over 4

=item * C<month> : (required) Specify the month (1-12) for which to return statistical climate data.

=back

=item * C<day> : B<Statistical Climate Data: Day aggregation>. Returns statistical climate indicators for a specific month of the year. For response details see L<official API doc|https://openweathermap.org/api/statistics-api>.
Parameters:

=over 4

=item * C<month> : (required) Specify the month (1-12) for which to return statistical climate data.

=item * C<day> : (required) Specify the day (1-31) of the month for which to return statistical climate data.

=back

=item * C<temp> : B<Accumulated temperature>: The sum, counted in degrees (Kelvin), by which the actual air temperature rises above or falls below a threshold level during the chosen time period. For response details see L<official API doc|https://openweathermap.org/api/accumulated-parameters>.
Parameters:

=over 4

=item * C<start> : (required) Start date. Unix timestamp (or iso date).

=item * C<end> : (required) End date. Unix timestamp (or iso date).

=item * C<threshold> : All values smaller than indicated value are not taken into account.

=back

=item * C<precip> : B<Accumulated precipitation>: The sum, counted in millimetres, of daily precipitation during the chosen time period. For response details see L<official API doc|https://openweathermap.org/api/accumulated-parameters>.
Parameters:

=over 4

=item * C<start> : (required) Start date. Unix timestamp (or iso date).

=item * C<end> : (required) End date. Unix timestamp (or iso date).

=back

=back

=head2 C<geo>

Geocoding API 1.0

    # Direct geocoding

    my $locations = $owm->geo(
        city  => $city?,  # City,country. Required if zip not specified.
        zip   => $zip?,   # Zip/postcode,country. Required if city not specified.
        limit => $limit   # Limit number of results.
    );

    my @locations = $owm->geo( ... );

    my ($lat, $lon) = ($locations[0]->{lat},$locations[0]->{lon});

    # Reverse geocoding

    my $locations = $owm->geo(
        lat   => $lat,    # Latitude.
        lon   => $lon,   # Longitude
        limit => $limit   # Limit number of results.
    );

    my @locations = $owm->geo( ... );

    my ($name, $country) = ($locations[0]->{name},$locations[0]->{country});

    # Checking for error with default error handling behaviour
    warn "Error" if @locations && $locations[0] eq 'error';
    warn "No results" if !@locations;

Will return a list of named locations with their central coordinates (lat/lon) that
match the request. The request can include either city or zip/postcode (geocoding),
or latitude/longitude (reverse geocoding).

All the OWM APIs work with coordinates, which are unambiguous. As a convenience,
the 2.5 API accepted city names or zip codes. This is now deprecated and you are
advised to use the geocoding to get the latitude/longitude of the desired location.
The Weather::OWM C<one_call> method also accepts city or zip as a convenience,
the top result of from the Geocoding API is used. You may want to use this API
directly yourself as well to verify the location is as intended.

For an explanation to the returned data, refer to the L<official API documentation|https://openweathermap.org/api/geocoding-api>.

Due to the data returned being an array, for the default error mode (C<return>),
on error a size-2 array will be returned: C<('error', HTTP::Response)>. Alternatives
are using the C<geo_response> function, or passing an C<error=>'die'> parameter
and using C<try/catch>.

Common parameters:

=over 4

=item * C<limit> : Limit the number of location results from 1 to 5. Currently, the API
default seems to be set to 1. Note that both direct and reverse geocoding can produce
more than one result (either different cities with the same name, of a location belonging
to different administrative units (e.g. city vs local municipality).

=back

Geocoding parameters:

=over 4

=item * C<city> : Expects C<city name>, C<city name,country code> or C<city name,state code,US>,
where C<country code> is ISO 3166. If the C<country code> is skipped, the result
may be ambiguous if there are similarly named/sized cities in different countries.

=item * C<zip> : Expects C<zip/post code,country code>, where C<country code> is ISO 3166.

=back

Reverse geocoding parameters:

=over 4

=item * C<lat> : Latitude.

=item * C<lon> : Longitude.

=back

=head1 ALTERNATIVE METHODS

The main methods handle the HTTP response errors with a C<die> that throws the status line.
There are alternative methods you can use that work exactly the same, except you
get the full L<HTTP::Response> object from the API endpoint, so that you can do
the error handling yourself.

=head2 C<one_call_response>

    my $response = $owm->one_call_response(
        %args
    );

Alternative to C<one_call> (same parameters).

=head2 C<get_weather_response>

    my $response = $owm->get_weather_response(
        %args
    );

Alternative to C<get_weather> (same parameters).

=head2 C<get_history_response>

    my $response = $owm->get_history_response(
        %args
    );

Alternative to C<get_history> (same parameters).

=head2 C<geo_response>

    my $response = $owm->geo_response(
        %args
    );

Alternative to C<geo> (same parameters).

=head1 HELPER METHODS

=head2 C<icon_url>

    my $url = $owm->icon_url($icon, $small?);

The APIs may return an C<icon> key which corresponds to a specific icon. The URL
to the 100x100 icon (png with transparent background) is provided by this function,
unless you pass C<$small> in which case you get the URL to the 50x50 icon.

=head2 C<icon_data>

    my $data = $owm->icon_data($icon, $small?);

Similar to L<icon_url> above, but downloads the png data (undef on error).


=head1 HELPER FUNCTIONS

=head2 C<ts_to_date>

    my $datetime = Weather::OWM::ts_to_date($timestamp, $utc?);

The OWM APIs usually return unix timestamps (key C<dt>). There are many ways to
convert them to human readable dates, but for convenience you can use C<ts_to_date>,
which will return the format C<YYYY-MM-DD HH:mm:ss> in your local time zone, or
C<YYYY-MM-DD HH:mm:ssZ> in UTC if the second argument is true.

=cut

my $geocache;

sub new {
    my $class = shift;

    my $self = {};
    bless($self, $class);

    my %args = @_;

    croak("key required ") unless $args{key};

    my %defaults = (
        scheme  => 'https',
        timeout => 30,
        agent   => "libwww-perl Weather::OWM/$VERSION",
        lang    => "en",
        units   => 'metric',
        error   => 'return',
    );
    $args{agent} = $args{ua}->agent() if $args{ua};
    $self->{$_} = $args{$_} || $defaults{$_} for keys %defaults;
    $self->{$_} = $args{$_} for qw/key ua debug/;

    croak("http or https scheme expected")
        if $self->{scheme} ne 'http' && $self->{scheme} ne 'https';

    return $self;
}

sub one_call {
    my $self = shift;
    return $self->_get(wantarray, 'one_call', @_);
}

sub get_weather {
    my $self = shift;
    return $self->_get(wantarray, 'weather', @_);
}

sub get_history {
    my $self = shift;
    return $self->_get(wantarray, 'history', @_);
}

sub geo {
    my $self = shift;
    return $self->_get(wantarray, 'geo', @_);
}

sub one_call_response {
    my $self = shift;
    my %args = $self->_preprocess_params('one_call', @_);

    $args{product} = '' if !$args{product} || $args{product} eq 'forecast';

    croak("product has to be 'forecast', 'historical' or 'daily'")
        if $args{product} && $args{product} ne 'historical' && $args{product} ne 'daily';

    $self->_geocode(\%args);

    _verify_lat_lon(\%args);

    if ($args{product}) { # Not forecast
        croak("date expected")
            unless $args{date};

        if ($args{product} eq 'daily') {
            $args{date} = ts_to_date($args{date})
                if $args{date} =~ /^\d+$/;

            if ($args{date} =~ /^(\d{4}-\d{2}-\d{2})/) {
                $args{date} = $1;
            } else {
                croak("date expected in the format YYYY-MM-DD");
            }
            croak("date of at least 1979-01-02 expected")
                unless $args{date} ge "1979-01-02";
        } elsif ($args{product} eq 'historical') {
            $args{date} = _date_to_ts($args{date})
                unless $args{date} =~ /^\d+$/;

            croak("dt / date of at least 1979-01-01 expected")
                unless $args{date} >= 283999530;
            $args{dt} = delete $args{date};
        }
    }

    return $self->_get_ua($self->_onecall_url(%args));
}

sub get_weather_response {
    my $self = shift;
    my %args = $self->_preprocess_params('weather', @_);

    _verify_lat_lon(\%args)
        unless $args{q} || $args{zip} || $args{city_id};

    return $self->_get_ua($self->_weather_url(%args));
}

sub get_history_response {
    my $self = shift;
    my %args = $self->_preprocess_params('history', @_);

    $args{product} ||= 'hourly';

    _verify_lat_lon(\%args)
        unless $args{q} || $args{zip} || $args{city_id};

    my %req = (
        hourly => ['start'],
        month  => ['month'],
        day    => [qw/month day/],
        temp   => [qw/start end/],
        precip => [qw/start end/],
    );

    my $req = $req{$args{product}};

    foreach (@$req) {
        croak("$_ is expected") unless $args{$_};
    }
    croak("end or cnt is expected")
        if $args{product} eq 'hourly' && !$args{end} && !$args{cnt};

    foreach (qw/start end/) {
        next unless $args{$_};
        $args{$_} = _date_to_ts($args{$_})
                unless $args{$_} =~ /^\d+$/;
    }

    return $self->_get_ua($self->_history_url(%args));
}

sub geo_response {
    my $self = shift;
    my %args = $self->_preprocess_params('geo', @_);

    if (defined $args{lat} && defined $args{lon}) {
        _verify_lat_lon(\%args);
    } else {
        croak("either both lat & lon, or either of city or zip parameters expected")
            unless $args{city} || $args{zip};        
    }

    return $self->_get_ua($self->_geo_url(%args));
}

sub icon_url {
    my $self = shift;
    my $icon = shift;
    my $sm   = shift;

    return unless $icon;

    $icon .= '@2x' unless $sm;
    return $self->{scheme} . "://openweathermap.org/img/wn/$icon.png";
}

sub icon_data {
    my $self = shift;
    my $url  = $self->icon_url(@_);

    if ($url) {
        my $res = $self->_get_ua($url);
        return $res->content if $res->is_success;
    }

    return;
}

sub ts_to_date {
    my $ts = shift;
    my $gm = shift;
    $gm = $gm ? 'Z' : '';
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        $gm ? gmtime($ts) : localtime($ts);
    $mon++;
    $year += 1900;
    return sprintf "%04d-%02d-%02d %02d:%02d:%02d%s", $year, $mon, $mday,
        $hour, $min, $sec, $gm;
}

sub _date_to_ts {
    my $date = shift;
    if ($date =~ /(\d{4})-(\d{2})-(\d{2})(?:.(\d{2}):(\d{2}):(\d{2})([Zz])?)?/) {
        return $7 ? timegm($6,$5,$4,$3,$2-1,$1) : timelocal($6,$5,$4,$3,$2-1,$1);
    }
    croak("unrecognized date format (try 'YYYY-MM-DD' or 'YYYY-MM-DD HH:mm:ss')");
}

sub _preprocess_params {
    my $self = shift;
    my $api  = shift;
    my %args = @_;

    $args{q} = delete($args{loc});
    if ($api eq 'one_call' || $api eq 'weather') {
        $args{$_} //= $self->{$_} for qw/lang units/;
        delete $args{units} if $args{units} eq 'standard';
        delete $args{lang}  if $args{lang} eq 'en';
    }
    $args{appid} = $self->{key};

    return %args;
}

sub _get {
    my $self      = shift;
    my $wantarray = shift;
    my $api       = shift;
    my %args      = @_;
    my $error     = delete $args{error} || $self->{error};

    my $resp =
          $api eq 'one_call' ? $self->one_call_response(%args)
        : $api eq 'weather'  ? $self->get_weather_response(%args)
        : $api eq 'history'  ? $self->get_history_response(%args)
        :                      $self->geo_response(%args);

    if ($resp->is_success) {
        return _output($resp->decoded_content, $wantarray ? ($args{mode} || 'json') : '');
    } else {
        if ($error eq 'die') {
            die $resp->status_line;
        } else {
            return $wantarray ? (error => $resp) : "ERROR: ".$resp->status_line;
        }
    }
}

sub _verify_lat_lon {
    my $args = shift;

    croak("lat between -90 and 90 expected")
        unless defined $args->{lat} && abs($args->{lat}) <= 90;

    croak("lon between -180 and 180 expected")
        unless defined $args->{lon} && abs($args->{lon}) <= 180;
}

sub _geocode {
    my $self = shift;
    my $args = shift;
    return if defined $args->{lat} && defined $args->{lon};

    my @location = $self->geo(city => $args->{city}, zip => $args->{zip}, limit => 1);
    croak("requested location not found") unless @location;
    $args->{$_} = $location[0]->{$_} for qw/lat lon/;
}

sub _get_ua {
    my $self = shift;
    my $url  = shift;
    $url = $self->{scheme}.$url;

    warn "$url\n" if $self->{debug};

    $self->{ua} = LWP::UserAgent->new() unless $self->{ua};
    $self->{ua}->agent($self->{agent});    
    $self->{ua}->timeout($self->{timeout});

    return $self->{ua}->get($url);
}

sub _weather_url {
    my $self = shift;
    my %args = @_;
    my $prod = delete $args{product} || 'current';
    my %products = (
        current  => 'weather',
        forecast => 'forecast',
        hourly   => 'forecast/hourly',
        daily    => 'forecast/daily',
        climate  => 'forecast/climate',
    );
    my $sub = 'api';
    $sub = 'pro' if $prod eq 'hourly' || $prod eq 'climate';
    croak('valid products: '.join(", ", keys %products))
        unless $products{$prod};

    return "://$sub.openweathermap.org/data/2.5/$products{$prod}?" . _join_args(\%args);
}

sub _history_url {
    my $self = shift;
    my %args = @_;
    my $prod = delete $args{product};
    my %products = (
        hourly => 'history/city',
        year   => 'aggregated/year',
        month  => 'aggregated/month',
        day    => 'aggregated/day',
        temp   => 'history/accumulated_temperature',
        precip => 'history/accumulated_precipitation',
    );

    $args{type} = 'hour' if $prod eq 'hourly';

    croak('valid products: '.join(", ", keys %products))
        unless $products{$prod};

    return "://history.openweathermap.org/data/2.5/$products{$prod}?" . _join_args(\%args);
}

sub _onecall_url {
    my $self = shift;
    my %args = @_;
    my $prod = delete $args{product} || '';
    $prod = '/timemachine' if $prod eq 'historical';
    $prod = '/day_summary' if $prod eq 'daily';

    return "://api.openweathermap.org/data/3.0/onecall$prod?" . _join_args(\%args);
}

sub _geo_url {
    my $self = shift;
    my %args = @_;

    return "://api.openweathermap.org/geo/1.0/reverse?" . _join_args(\%args)
        if defined $args{lat} && defined $args{lon};

    $args{q} = delete $args{city};
    return "://api.openweathermap.org/geo/1.0/direct?" . _join_args(\%args);
}

sub _join_args {
    my $args = shift;
    return join "&", map {defined $args->{$_} ? "$_=$args->{$_}" : ()} keys %$args;
}

sub _output {
    my $str    = shift;
    my $format = shift;

    return $str unless $format;

    if ($format eq 'json') {
        require JSON;
        return _deref(JSON::decode_json($str));
    } elsif ($format eq 'xml') {
        require XML::Simple;
        return _deref(XML::Simple::XMLin($str));
    }
    return (data => $str);
}

sub _deref {
    my $ref = shift;
    die "Could not decode response body" unless $ref;
    return $ref unless ref($ref);
    return %$ref if ref($ref) eq 'HASH';
    return @$ref;
}

=head1 PERL WEATHER MODULES

A quick listing of Perl modules for current weather and forecasts from various sources:

=head2 OpenWeatherMap

OpenWeatherMap uses various weather sources combined with their own ML and offers
a couple of free endpoints (the v2.5 current weather and 5d/3h forecast) with generous
request limits. Their newer One Call 3.0 API also offers some free usage (1000 calls/day)
and the cost is per call above that. If you want access to history APIs, extended
hourly forecasts etc, there are monthly subscriptions. If you want to access an API
that is missing from L<Weather::OWM>, feel free to ask the author.

Note that there is an older L<Weather::OpenWeatherMap> module, but it is no longer
maintained and only supports the old (v2.5) Weather API. I looked into updating it
for my purposes, but it was more complex (returns objects, so a new object definition
is required per API endpoint added etc) and with more dependencies (including L<Moo>),
than what I wanted from such a module.

=head2 Apple WebKit

An alternative source for multi-source forecasts is Apple's WeatherKit (based on
the old Dark Sky weather API). It offers 500k calls/day for free, but requires a
paid Apple developer account. You can use L<Weather::WeatherKit>, which is very
similar to this module (same author).

=head2 7Timer!

If you are interested in astronomy/stargazing the 7Timer! weather forecast might be
useful. It uses the standard NOAA forecast, but calculates astronomical seeing and
transparency. It is completely free and can be accessed with L<Weather::Astro7Timer>,
which is another very similar to this module (same author).

=head2 YR.no

Finally, the Norwegian Meteorological Institute offers the free YR.no service, which
can be accessed via L<Weather::YR>, although I am not affiliated and have not tested
that module.

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests on L<GitHub|https://github.com/dkechag/Weather-OWM>.

=head1 GIT

L<https://github.com/dkechag/Weather-OWM>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
