package Weather::Meteo;

use strict;
use warnings;
use autodie;

use Carp;
use CHI;
use JSON::MaybeXS;
use LWP::UserAgent;
use Object::Configure;
use Params::Get 0.13;
use Params::Validate::Strict;
use POSIX ();
use Readonly;
use Return::Set;
use Scalar::Util;
use Sub::Private { mode => 'enforce' };
use Sub::Protected;
use Time::HiRes;
use URI;

# ---------------------------------------------------------------------------
# Configuration.  Everything that was a magic number or string lives here so
# that there is exactly one place to change it.
# ---------------------------------------------------------------------------

# Archive API host (historical data from 1940 onwards)
Readonly my $DEFAULT_HOST => 'archive-api.open-meteo.com';
# Forecast API host (up to 16 days ahead)
Readonly my $FORECAST_HOST => 'api.open-meteo.com';
Readonly my $FIRST_YEAR     => 1940;
Readonly my $EXPIRES_IN     => '1 hour';
Readonly my $MIN_INTERVAL   => 0;
Readonly my $MAX_RETRIES    => 3;
Readonly my $RETRY_DELAY    => 1;
Readonly my $MAX_RETRY_WAIT => 60;
# Default timezone when neither the caller nor the location object supplies one
Readonly my $DEFAULT_TZ     => 'Europe/London';
Readonly my $DEFAULT_DAYS   => 7;
Readonly my $MAX_DAYS       => 16;

# The fields requested from the API are fixed, so that callers always get the
# same structure back and the cache never mixes shapes.
Readonly my $HOURLY_FIELDS => 'temperature_2m,rain,snowfall,weathercode';
Readonly my $DAILY_FIELDS  => 'weathercode,temperature_2m_max,temperature_2m_min,'
	. 'rain_sum,snowfall_sum,precipitation_hours,windspeed_10m_max,'
	. 'windgusts_10m_max,sunrise,sunset';
Readonly my @UNIT_PAIRS    => (windspeed_unit => 'mph', precipitation_unit => 'inch');

# Atomic groups prevent O(n) backtracking (ReDoS); capturing also untaints.
Readonly my $COORD_RE => qr/\A(-?(?>\d+)(?:\.(?>\d+))?)\z/;
Readonly my $DATE_RE  => qr/\A(\d{4}-\d{2}-\d{2})\z/;

# Only transient failures are worth retrying; a 500 or 404 will not fix itself.
Readonly my %RETRYABLE_STATUS => map { $_ => 1 } (429, 502, 503, 504);

# Constructor arguments that must be validated (and thereby untainted).
# Each entry is [ pattern, message key ]; the pattern captures the safe value.
Readonly my %PARAM_PATTERNS => (
	host        => [ qr/\A([A-Za-z0-9][A-Za-z0-9.\-]*(?::\d{1,5})?)\z/, 'invalid_host' ],
	max_retries => [ qr/\A(\d{1,3})\z/,                                'invalid_max_retries' ],
	retry_delay => [ qr/\A(\d{1,4}(?:\.\d{1,3})?)\z/,                  'invalid_retry_delay' ],
);

# Default (English) message table.  Placeholders are written {name}.  A value
# may also be a hashref of plural/gender variants (see i18n()).  Callers can
# override any entry through the 'messages' constructor argument.
Readonly my %MESSAGES => (
	usage_weather       => 'Usage: weather(latitude => $latitude, longitude => $longitude, date => "YYYY-MM-DD")',
	usage_forecast      => 'Usage: forecast(latitude => $latitude, longitude => $longitude)',
	usage_sunrise       => 'Usage: sunrise_sunset(latitude => $latitude, longitude => $longitude)',
	invalid_coordinates => '{class}: Invalid latitude/longitude format ({latitude}, {longitude})',
	invalid_date_format => 'Invalid date format. Expected YYYY-MM-DD',
	not_a_date          => "'{date}' is not a valid date",
	days_range          => 'days must be between {min} and {max}; defaulting to {default}',
	api_error           => '{class}: API error: {reason}',
	http_error          => '{class}: {url} API returned error: {status}',
	bad_response        => '{class}: UA->get did not return a valid HTTP response',
	json_parse          => 'Failed to parse JSON response: {error}',
	bad_ua              => "'ua' argument must be an object with a get() method",
	ua_undef            => 'ua() requires a defined value',
	invalid_host        => "Invalid host '{value}': must be a plain hostname",
	invalid_max_retries => "Invalid max_retries '{value}': must be a non-negative integer",
	invalid_retry_delay => "Invalid retry_delay '{value}': must be a non-negative number",
	invalid_messages    => "'messages' argument must be a hash reference",
);

=head1 NAME

Weather::Meteo - Interface to L<https://open-meteo.com> for historical and forecast weather data

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';

=head1 SYNOPSIS

The C<Weather::Meteo> module provides an interface to the Open-Meteo API for retrieving
historical weather data from 1940 and weather forecasts up to 16 days ahead.
It allows users to fetch weather information by specifying latitude, longitude, and a date.
The module supports object-oriented usage and allows customisation of the HTTP user agent.

      use Weather::Meteo;

      my $meteo = Weather::Meteo->new();

      # Historical weather
      my $weather = $meteo->weather({ latitude => 0.1, longitude => 0.2, date => '2022-12-25' });

      # Forecast (default 7 days)
      my $forecast = $meteo->forecast({ latitude => 51.34, longitude => 1.42 });

      # Sunrise and sunset for a specific date
      my $times = $meteo->sunrise_sunset({ latitude => 51.34, longitude => 1.42, date => '2025-06-21' });
      print "Sunrise: $times->{sunrise}\n";

      # Retry transient API failures up to 5 times, starting with a 2 second delay
      my $patient = Weather::Meteo->new(max_retries => 5, retry_delay => 2);

      # Reword or translate the warnings and errors
      my $french = Weather::Meteo->new(messages => {
          not_a_date => "'{date}' n'est pas une date valide",
      });

=over 4

=item * Caching

Identical requests are cached (using L<CHI> or a user-supplied caching object),
reducing the number of HTTP requests to the API and speeding up repeated queries.

When a request is made,
a cache key is constructed from the coordinates, date, and timezone.
If a cached response exists it is returned immediately,
avoiding unnecessary API calls.

=item * Rate-Limiting

A minimum interval between successive API calls can be enforced to ensure that the
API is not overwhelmed and to comply with any request throttling requirements.

Rate-limiting is implemented using L<Time::HiRes>.
A minimum interval between API calls can be specified via the C<min_interval> parameter
in the constructor.
Before making an API call,
the module checks how much time has elapsed since the last request and,
if necessary,
sleeps for the remaining time.

=back

=head1 METHODS

=head2 new

    my $meteo = Weather::Meteo->new();

    # Custom user agent with proxy support
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $meteo = Weather::Meteo->new(ua => $ua);

    # Clone an existing object and override one slot
    my $clone = $meteo->new(host => 'custom.example.com');

Creates a new C<Weather::Meteo> instance.
When called on an existing C<Weather::Meteo> object,
clones that object and merges the supplied parameters.

=over 4

=item * C<cache>

A caching object.
If not provided,
an in-memory cache is created with a default expiration of one hour.

=item * C<host>

The archive API host endpoint.
Defaults to C<archive-api.open-meteo.com>.

Must be a plain DNS hostname - letters, digits, hyphens, and dots - with an
optional port suffix (e.g. C<mock.example.com:8080>).
Values containing C<@>, path segments, or other special characters are rejected
with a C<croak> to prevent Server-Side Request Forgery (SSRF) via the
C<WEATHER__METEO__host> environment variable or configuration file.
Falsy values (C<undef>, C<"">, C<0>) fall back to the default silently.

=item * C<logger>

An optional logger object.
Must respond to C<error()>.
When supplied, API errors are reported through this logger in addition to C<Carp::carp>.

=item * C<max_retries>

Maximum number of times a request is retried after a transient failure:
HTTP 429 (Too Many Requests), 502, 503 or 504.
Defaults to C<3>.
Set to C<0> to disable retrying.
Other errors, including HTTP 500 and 404, are never retried.

=item * C<messages>

A hashref of message keys to replacement text, for translating or rewording
the module's warnings and errors.
See L</i18n> for the keys, the placeholder syntax and plural support.
Defaults to the built-in English messages.

=item * C<min_interval>

Minimum number of seconds to wait between API requests.
May be fractional, for example C<0.5>.
Defaults to C<0> (no delay).
Use this option to enforce rate-limiting.

=item * C<retry_delay>

Base delay in seconds before the first retry.
The delay doubles on each subsequent retry (C<retry_delay>, C<2 * retry_delay>, ...).
A numeric C<Retry-After> header from the server takes precedence.
Waits are capped at 60 seconds.
Defaults to C<1>.

=item * C<ua>

An object to use for HTTP requests.
If not provided, a default C<LWP::UserAgent> is created.
Must respond to C<get()>.

=back

The class can be configured at runtime using environment variables and configuration files,
for example,
setting C<$ENV{'WEATHER__METEO__carp_on_warn'}> causes warnings to use L<Carp>.
For more information about runtime configuration,
see L<Object::Configure>.

=head3 EXAMPLE

    # Minimal -- use all defaults
    my $meteo = Weather::Meteo->new();

    # Custom UA with throttling
    use LWP::UserAgent::Throttled;
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('open-meteo.com' => 1);
    my $meteo = Weather::Meteo->new(ua => $ua, min_interval => 1);

    # Clone the object but change the host for integration testing
    my $test_meteo = $meteo->new(host => 'mock.example.com');

=head3 API SPECIFICATION

=head4 Input

All parameters are optional.
They may be supplied as a hashref or a flat key/value list.
When C<$class> is an existing C<Weather::Meteo> object the call clones it,
merging any supplied parameters.

    {
        ua           => { type => 'object', can => 'get',   optional => 1 },
        cache        => { type => 'object',                  optional => 1 },
        host         => { type => 'scalar',                  optional => 1 },
        min_interval => { type => 'scalar',                  optional => 1 },
        max_retries  => { type => 'scalar',                  optional => 1 },
        messages     => { type => 'hashref',                 optional => 1 },
        retry_delay  => { type => 'scalar',                  optional => 1 },
        logger       => { type => 'object', can => 'error', optional => 1 },
    }

=head4 Output

    { type => 'object', isa => 'Weather::Meteo' }

=head3 MESSAGES

    Message                                            Type   Trigger
    -------------------------------------------------  -----  -----------------------------------
    'ua' argument must be an object with a get()       croak  clone called with an invalid ua arg
    method
    Invalid host '$host': must be a plain hostname     croak  host contains @, /, or other chars
                                                              that are not safe in a DNS label
    Invalid max_retries '$n': must be a non-negative   croak  max_retries is not a small integer
    integer
    Invalid retry_delay '$d': must be a non-negative   croak  retry_delay is not a plain number
    number
    'messages' argument must be a hash reference       croak  messages is not a hashref

=cut

sub new {
	my $class  = shift;
	my $params = Params::Get::get_params(undef, \@_) || {};

	# Weather::Meteo::new() used rather than Weather::Meteo->new()
	$class //= __PACKAGE__;

	# Clone path: merge new params over the existing object's fields
	return $class->_clone($params) if Scalar::Util::blessed($class);

	$params = Object::Configure::configure($class, $params);

	# A falsy host (undef, "", 0) silently falls back to the default host
	delete $params->{host} unless $params->{host};

	# Validate and untaint host and the retry settings.  Host validation
	# prevents SSRF via the WEATHER__METEO__host env var or a config file.
	foreach my $name (sort keys %PARAM_PATTERNS) {
		_untaint_param($class, $params, $name) if defined($params->{$name});
	}

	if(defined($params->{messages}) && ref($params->{messages}) ne 'HASH') {
		$class->_croak('invalid_messages');
	}

	my $ua = $params->{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
	}

	my $cache = $params->{cache} || CHI->new(
		driver     => 'Memory',
		global     => 1,
		expires_in => $EXPIRES_IN,
	);

	return bless {
		min_interval => $params->{min_interval} || $MIN_INTERVAL,
		last_request => 0,
		%{$params},
		cache => $cache,
		host  => $params->{host} || $DEFAULT_HOST,
		ua    => $ua,
	}, $class;
}

=head2 weather

    use Geo::Location::Point;

    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    my $weather  = $meteo->weather($ramsgate, '2022-12-25');

    # Print snowfall at 1AM on Christmas morning in Ramsgate
    my @snowfall = @{$weather->{'hourly'}->{'snowfall'}};
    print 'Snowfall at 1AM: ', $snowfall[1], " cm\n";

    use DateTime;
    my $dt = DateTime->new(year => 2024, month => 2, day => 1);
    $weather = $meteo->weather({ location => $ramsgate, date => $dt });

The date argument can be an ISO-8601 formatted string (C<YYYY-MM-DD>),
or any object that supports C<strftime>.

Takes an optional C<tz> argument containing the time zone.
If not given, the module tries to derive it from the location object;
set C<TIMEZONEDB_KEY> to your API key from L<https://timezonedb.com> to enable that.
If all else fails, the module falls back to C<Europe/London>.

Dates before 1940 return C<undef> silently.
Invalid date strings cause a C<carp> and return C<undef>.
Missing required arguments or non-numeric coordinates cause a C<croak>.

On success returns a hashref with at minimum an C<hourly> key.
The C<daily> key includes C<sunrise> and C<sunset> as ISO-8601 datetime strings
(e.g. C<2022-12-25T08:09>), as well as temperature, precipitation, and wind fields.
Returns C<undef> if the API returns an error, if the JSON cannot be
parsed, or if the response contains no C<hourly> key.

=head3 EXAMPLE

    my $meteo   = Weather::Meteo->new();
    my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });

    if(defined($weather)) {
        my $max_temp = $weather->{'daily'}->{'temperature_2m_max'}[0];
        my $sunrise  = $weather->{'daily'}->{'sunrise'}[0];
        my @temps    = @{$weather->{'hourly'}->{'temperature_2m'}};
        print "Max temp: ${max_temp}C  Sunrise: $sunrise\n";
        print "Temp at noon: $temps[12]C\n";
    }

=head3 API SPECIFICATION

=head4 Input

Three call forms are accepted.

    # Form 1 and 2 -- hashref or flat list
    {
        latitude  => { type => 'scalar' },
        longitude => { type => 'scalar' },
        date      => { type => 'scalar | object' },
        tz        => { type => 'scalar', optional => 1 },
        location  => { type => 'object', can => 'latitude', optional => 1 },
    }

    # Form 3 -- positional: ($location_obj, $date)
    # $location_obj must respond to latitude() and longitude()

=head4 Output

    { type => 'hashref', min => 1 }   # success -- contains 'hourly' key
    undef                              # pre-1940 date, bad input, or API error

=head3 MESSAGES

    Message                                              Type   Trigger
    ---------------------------------------------------  -----  ----------------------------------
    Usage: weather(latitude => ...)                      croak  lat, lon, or date is missing
    Invalid latitude/longitude format ($lat, $lon)       croak  coordinate is not numeric
    '$date' is not a valid date                          carp   date string is not YYYY-MM-DD
    Invalid date format. Expected YYYY-MM-DD             croak  date starts with a year but is not
                                                               exactly YYYY-MM-DD (also if
                                                               strftime() returned something else)
    UA->get did not return a valid HTTP response         carp   UA returned non-response object
    $url API returned error: $status                     carp   HTTP 4xx/5xx response
    Failed to parse JSON response: $err                  carp   response body is not valid JSON
                                                               ($err is the exception with control
                                                               chars stripped and length capped at
                                                               200 chars to prevent log injection)
    Weather::Meteo: API error: $reason                   carp   API returned {"error":true,...}

=head3 PSEUDOCODE

    params = _location_params(args)         # hashref, flat list or (location, date)
    (lat, lon) = _coordinates(params)       # croak if missing or not decimal numbers
    date = _archive_date(params.date)
      # object with strftime => strftime('%F'); other strings must start with a year
      # return undef quietly if year < 1940; croak unless exactly YYYY-MM-DD
    return undef if date is undef
    url = _build_url(archive host, '/v1/archive', hourly+daily fields, units)
    return _cached_report(key, url)
      # cache hit => return it
      # else _api_get(url): _fetch_json() with retry on 429/502/503/504;
      #   carp and undef on HTTP error, bad JSON, or {"error":true}
      # undef if no 'hourly' key; else cache it and return hashref (Return::Set)

=cut

sub weather {
	my $self   = shift;
	my $params = $self->_location_params(\@_, 'date', 2, 2);

	my ($latitude, $longitude) = @{ $self->_coordinates($params, 'usage_weather', 'date') };
	my $tz   = $params->{'tz'} || $DEFAULT_TZ;
	my $date = $self->_archive_date($params->{'date'});

	# undef means a date before 1940 or one that is not a date at all
	return unless defined($date);

	my $url = _build_url($self->{host}, '/v1/archive', _report_query(
		$latitude, $longitude, $tz, [ start_date => $date, end_date => $date ],
	));

	return $self->_cached_report("weather:$latitude:$longitude:$date:$tz", $url);
}

=head2 forecast

    my $meteo    = Weather::Meteo->new();
    my $forecast = $meteo->forecast({ latitude => 51.34, longitude => 1.42 });
    my @temps    = @{$forecast->{'hourly'}->{'temperature_2m'}};

    # Request 3 days of forecast
    $forecast = $meteo->forecast({ latitude => 51.34, longitude => 1.42, days => 3 });

    use Geo::Location::Point;
    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    $forecast = $meteo->forecast($ramsgate);
    $forecast = $meteo->forecast($ramsgate, 5);

Fetches weather forecast data from L<https://api.open-meteo.com>.
Returns up to 16 days of hourly and daily data.
The C<daily> key of the response includes C<sunrise> and C<sunset> ISO-8601 datetime strings.

Takes an optional C<days> argument (integer 1-16, default 7).
Anything that is not a whole number from 1 to 16, such as C<0>, C<17>, C<1.5> or C<abc>,
is replaced by 7 with a warning.
Takes an optional C<tz> argument for the time zone; defaults to C<Europe/London>.

On success returns a hashref containing at minimum the key C<hourly>.
Returns C<undef> if the API returns an error, if the JSON cannot be parsed,
or if the response contains no C<hourly> key.

=head3 EXAMPLE

    my $meteo    = Weather::Meteo->new();
    my $forecast = $meteo->forecast({ latitude => 51.34, longitude => 1.42, days => 5 });

    if(defined($forecast)) {
        my $daily   = $forecast->{'daily'};
        my @sunrises = @{$daily->{'sunrise'}};
        my @max_temps = @{$daily->{'temperature_2m_max'}};
        for my $i (0 .. $#sunrises) {
            print "Day $i: sunrise $sunrises[$i], max $max_temps[$i]C\n";
        }
    }

=head3 API SPECIFICATION

=head4 Input

Three call forms are accepted.

    # Form 1 and 2 -- hashref or flat list
    {
        latitude  => { type => 'scalar' },
        longitude => { type => 'scalar' },
        days      => { type => 'scalar',                optional => 1 },
        tz        => { type => 'scalar',                optional => 1 },
        location  => { type => 'object', can => 'latitude', optional => 1 },
    }

    # Form 3 -- positional: ($location_obj) or ($location_obj, $days)
    # $location_obj must respond to latitude() and longitude()

=head4 Output

    { type => 'hashref', min => 1 }   # success -- contains 'hourly' key
    undef                              # bad input or API error

=head3 MESSAGES

    Message                                              Type   Trigger
    ---------------------------------------------------  -----  ----------------------------------
    Usage: forecast(latitude => ...)                     croak  lat or lon is missing
    Invalid latitude/longitude format ($lat, $lon)       croak  coordinate is not numeric
    days must be between 1 and 16; defaulting to 7       carp   days argument is out of range
    UA->get did not return a valid HTTP response         carp   UA returned non-response object
    $url API returned error: $status                     carp   HTTP 4xx/5xx response
    Failed to parse JSON response: $err                  carp   response body is not valid JSON
                                                               ($err is the exception with control
                                                               chars stripped and length capped at
                                                               200 chars to prevent log injection)
    Weather::Meteo: API error: $reason                   carp   API returned {"error":true,...}

=head3 PSEUDOCODE

    params = _location_params(args)         # hashref, flat list or (location, days)
    (lat, lon) = _coordinates(params)       # croak if missing or not decimal numbers
    days = params.days // 7
    if days is not an integer in 1..16: carp 'days_range'; days = 7
    url = _build_url(forecast host, '/v1/forecast', forecast_days, hourly+daily, units)
    return _cached_report(key, url)         # as for weather()

=cut

sub forecast {
	my $self   = shift;
	my $params = $self->_location_params(\@_, 'days', 1, 2);

	my ($latitude, $longitude) = @{ $self->_coordinates($params, 'usage_forecast') };
	my $tz   = $params->{'tz'} || $DEFAULT_TZ;
	my $days = $params->{'days'} // $DEFAULT_DAYS;

	# Capturing untaints; out-of-range values are corrected rather than fatal
	# so that a typo costs the caller a warning, not an exception.
	if($days =~ /\A(\d+)\z/ && $1 >= 1 && $1 <= $MAX_DAYS) {
		$days = $1;
	} else {
		$self->_carp('days_range', { min => 1, max => $MAX_DAYS, default => $DEFAULT_DAYS });
		$days = $DEFAULT_DAYS;
	}

	my $url = _build_url($FORECAST_HOST, '/v1/forecast', _report_query(
		$latitude, $longitude, $tz, [ forecast_days => $days ],
	));

	return $self->_cached_report("forecast:$latitude:$longitude:$days:$tz", $url);
}

=head2 sunrise_sunset

    my $meteo = Weather::Meteo->new();

    # Historical date -- uses the archive endpoint
    my $times = $meteo->sunrise_sunset({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
    print "Sunrise: $times->{sunrise}\n";
    print "Sunset:  $times->{sunset}\n";

    # Today (no date given -- uses the forecast endpoint)
    $times = $meteo->sunrise_sunset({ latitude => 51.34, longitude => 1.42 });

    use Geo::Location::Point;
    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    $times = $meteo->sunrise_sunset($ramsgate, '2022-12-25');

Returns a hashref with C<sunrise> and C<sunset> ISO-8601 datetime strings
(e.g. C<2022-12-25T08:09>) for the given location and date.

If no date is supplied, today is used and the forecast endpoint is queried.
For historical dates (strictly before today) the archive endpoint is used.
For today and future dates the forecast endpoint (L<https://api.open-meteo.com>) is used.

Takes an optional C<tz> argument for the time zone; defaults to C<Europe/London>.

Returns C<undef> if the API returns an error or if the response does not contain
sunrise/sunset data.

=head3 EXAMPLE

    my $meteo = Weather::Meteo->new();
    my $times = $meteo->sunrise_sunset({ latitude => 48.8566, longitude => 2.3522 });

    if(defined($times)) {
        print "Paris sunrise today: $times->{sunrise}\n";
        print "Paris sunset today:  $times->{sunset}\n";
    }

    # Historical query
    my $solstice = $meteo->sunrise_sunset({
        latitude  => 51.4779,
        longitude => -0.0015,
        date      => '2024-06-21',
        tz        => 'Europe/London',
    });
    print "Greenwich sunrise on summer solstice 2024: $solstice->{sunrise}\n";

=head3 API SPECIFICATION

=head4 Input

Three call forms are accepted.

    # Form 1 and 2 -- hashref or flat list
    {
        latitude  => { type => 'scalar' },
        longitude => { type => 'scalar' },
        date      => { type => ['scalar', 'object'], optional => 1 },
        tz        => { type => 'scalar',           optional => 1 },
        location  => { type => 'object', can => 'latitude', optional => 1 },
    }

    # Form 3 -- positional: ($location_obj) or ($location_obj, $date)
    # $location_obj must respond to latitude() and longitude()

=head4 Output

    { type => 'hashref' }   # { sunrise => STRING, sunset => STRING }
    undef                    # bad input or API error

=head3 MESSAGES

    Message                                              Type   Trigger
    ---------------------------------------------------  -----  ----------------------------------
    Usage: sunrise_sunset(latitude => ...)               croak  lat or lon is missing
    Invalid latitude/longitude format ($lat, $lon)       croak  coordinate is not numeric
    '$date' is not a valid date                          carp   date string is not YYYY-MM-DD
    UA->get did not return a valid HTTP response         carp   UA returned non-response object
    $url API returned error: $status                     carp   HTTP 4xx/5xx response
    Failed to parse JSON response: $err                  carp   response body is not valid JSON
                                                               ($err is the exception with control
                                                               chars stripped and length capped at
                                                               200 chars to prevent log injection)
    Weather::Meteo: API error: $reason                   carp   API returned {"error":true,...}

=head3 PSEUDOCODE

    params = _location_params(args)         # hashref, flat list or (location, date)
    (lat, lon) = _coordinates(params)       # croak if missing or not decimal numbers
    date = params.date (strftime('%F') if an object)
    if date is defined and not YYYY-MM-DD: carp 'not_a_date'; return undef
    use_forecast = date is undef or date >= today (host-local date)
    return cached {sunrise, sunset} if present
    url = _build_url(forecast or archive host, daily=sunrise,sunset)
    daily = _api_get(url).daily             # carp and undef on any failure
    return undef unless first sunrise and first sunset are both defined
    cache and return { sunrise => ..., sunset => ... }

=cut

sub sunrise_sunset {
	my $self   = shift;
	my $params = $self->_location_params(\@_, 'date', 1, 2);

	my ($latitude, $longitude) = @{ $self->_coordinates($params, 'usage_sunrise') };
	my $tz   = $params->{'tz'} || $DEFAULT_TZ;
	my $date = $params->{'date'};

	$date = $date->strftime('%F') if Scalar::Util::blessed($date) && $date->can('strftime');

	if(defined($date)) {
		# Capturing untaints; anything but YYYY-MM-DD is rejected
		my ($clean) = ($date =~ $DATE_RE);
		if(!defined($clean)) {
			$self->_carp('not_a_date', { date => $date });
			return;
		}
		$date = $clean;
	}

	# Today and the future are not in the archive yet, so use the forecast
	# endpoint for them.  With no date at all, "today" is the safest default.
	my $today        = POSIX::strftime('%Y-%m-%d', localtime());
	my $use_forecast = !defined($date) || ($date ge $today);
	$date //= $today;

	my $cache_key = "sunrise_sunset:$latitude:$longitude:$date:$tz";
	my $result    = $self->{'cache'}->get($cache_key);

	if(!$result) {
		my $url = _build_url(
			$use_forecast ? $FORECAST_HOST : $self->{host},
			$use_forecast ? '/v1/forecast' : '/v1/archive',
			[
				latitude   => $latitude,
				longitude  => $longitude,
				start_date => $date,
				end_date   => $date,
				daily      => 'sunrise,sunset',
				timezone   => $tz,
			],
		);

		# Both values must be present or the answer is useless
		my $daily = ($self->_api_get($url) // {})->{'daily'};
		my ($sunrise, $sunset) = map { _first_element($daily, $_) } qw(sunrise sunset);
		if(defined($sunrise) && defined($sunset)) {
			$result = { sunrise => $sunrise, sunset => $sunset };
			$self->{'cache'}->set($cache_key, $result);
		}
	}

	return $result;
}

=head2 ua

Accessor method to get and set the C<UserAgent> object used internally.
You can call C<env_proxy> for example, to get proxy information from
environment variables:

    $meteo->ua()->env_proxy(1);

You can also replace the user agent entirely:

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('open-meteo.com' => 1);
    $meteo->ua($ua);

=head3 EXAMPLE

    my $meteo = Weather::Meteo->new();

    # Getter: inspect the current UA
    my $ua = $meteo->ua();
    $ua->env_proxy(1);

    # Setter: replace with a throttled UA
    use LWP::UserAgent::Throttled;
    $meteo->ua(LWP::UserAgent::Throttled->new());

=head3 API SPECIFICATION

=head4 Input

When called with no arguments acts as a getter; the input schema is empty.
When called with an argument the argument must be an object that responds to C<get>:

    { ua => { type => 'object', can => 'get' } }

=head4 Output

    { type => 'object', can => 'get' }

=head3 MESSAGES

    Message                                              Type   Trigger
    ---------------------------------------------------  -----  ----------------------------------
    ua() requires a defined value                        croak  ua(undef) called
    must be an object that understands the get method    croak  ua arg lacks get() method

=cut

sub ua {
	my $self = shift;

	if(@_) {
		my $params = Params::Validate::Strict::validate_strict({
			args => Params::Get::get_params('ua', \@_),
			schema => {
				ua => {
					type => 'object',
					can  => 'get'
				}
			}
		});
		# Reject undef explicitly before it silently corrupts $self->{ua}
		$self->_croak('ua_undef') unless defined($params->{ua});
		$self->{ua} = $params->{ua};
	}

	return $self->{ua};
}

=head2 i18n

    my $text = $meteo->i18n('days_range', { min => 1, max => 16, default => 7 });

Returns the text of a diagnostic message, with its placeholders filled in.
Every warning and error raised by this module is produced through this method,
so each one can be translated or reworded without touching the code.

Messages are looked up first in the C<messages> hashref given to L</new>,
then in the built-in English table.
Placeholders are written C<{name}> and are replaced from the arguments hashref.
A placeholder with no matching argument is left as it is, so a missing value is
visible in the output instead of silently vanishing.

A message may be a hashref of variants instead of a string.
The variant is chosen by the C<count> argument (C<one> if it is 1, otherwise
C<other>) and, if a C<gender> argument is also given, the variant named
C<one_F<gender>> or C<other_F<gender>> is preferred when it exists.
Only the English rule for singular and plural is built in; translators for
languages with more plural forms should put the form they need under C<other>
or add their own keys and select them with C<count>.

If the arguments hashref has a C<sprintf> arrayref, the message is first passed
through C<sprintf> with those values, which allows C<%s> style translations.

Can be called as a class method.
Confesses (with a stack trace) if the key is unknown, because that is a
programming error and not something a caller can recover from.

=head3 EXAMPLE

    # Built-in English
    print $meteo->i18n('invalid_host', { value => 'bad host' }), "\n";

    # German overrides, with a plural
    my $de = Weather::Meteo->new(messages => {
        days_range => 'Tage muessen zwischen {min} und {max} liegen; verwende {default}',
        days_left  => { one => 'noch {count} Tag', other => 'noch {count} Tage' },
    });
    print $de->i18n('days_left', { count => 3 }), "\n";    # noch 3 Tage

=head3 API SPECIFICATION

=head4 Input

    {
        key  => { type => 'string' },
        args => { type => 'hashref', optional => 1 },
    }

=head4 Output

    { type => 'string', min => 1 }

=head3 MESSAGES

    Message                                              Type     Trigger
    ---------------------------------------------------  -------  ----------------------------------
    Weather::Meteo: no message defined for key '$key'    confess  key is in neither table
    Weather::Meteo: no '$category' variant in message    confess  variant hashref lacks one/other

=cut

sub i18n {
	my ($self, $key, $args) = @_;
	$args //= {};

	# Per-object overrides win over the built-in English table
	my $overrides = ref($self) ? $self->{messages} : undef;
	my $format    = ($overrides && exists($overrides->{$key})) ? $overrides->{$key} : $MESSAGES{$key};

	# An unknown key is a programming error, so show the caller's stack
	Carp::confess("Weather::Meteo: no message defined for key '$key'") unless defined($format);

	# A hashref holds plural/gender variants, e.g. { one => ..., other => ..., one_f => ... }
	$format = _select_variant($format, $args) if ref($format) eq 'HASH';

	# Positional sprintf arguments are optional and applied first, so that a
	# '%' inside a {name} substitution is never mistaken for a conversion.
	if(ref($args->{sprintf}) eq 'ARRAY') {
		$format = sprintf($format, @{$args->{sprintf}});
	}

	# Named placeholders; unknown names are left visible rather than dropped
	$format =~ s{\{(\w+)\}}{ exists($args->{$1}) ? ($args->{$1} // q{}) : "{$1}" }ge;

	return $format;
}

# ---------------------------------------------------------------------------
# _select_variant -- pick a plural/gender variant from a message hashref
#
# Purpose:     Let a translation say "1 day" and "2 days" (or a gendered form)
#              without the calling code knowing the rules.  Only the English
#              rule (1 is singular, everything else plural) is built in;
#              translators for other languages supply the right keys themselves.
# Entry:       $variants -- hashref with some of: one, other, <category>_<gender>
#              $args     -- hashref; 'count' picks the category (default: other),
#                           'gender' picks a gendered variant if one exists
# Exit:        the chosen format string; confesses if no variant matches
# Side effects: none
# ---------------------------------------------------------------------------
sub _select_variant :Private {
	my ($variants, $args) = @_;

	my $category = (defined($args->{count}) && $args->{count} == 1) ? 'one' : 'other';
	my ($chosen) = grep { defined } (
		(defined($args->{gender}) ? $variants->{"${category}_$args->{gender}"} : undef),
		$variants->{$category},
		$variants->{other},
	);
	Carp::confess("Weather::Meteo: no '$category' variant in message") unless defined($chosen);

	return $chosen;
}

# ---------------------------------------------------------------------------
# _log_error -- pass a message to the optional logger
#
# Purpose:     Report errors to a caller-supplied logger as well as via Carp.
# Entry:       $self    -- object or class name (class names have no logger)
#              $message -- text to log
# Exit:        $self, so calls can be chained
# Side effects: calls $self->{logger}->error()
# ---------------------------------------------------------------------------
sub _log_error :Protected {
	my ($self, $message) = @_;

	# eval guard: Log::Abstraction::error() is fatal (it dies), but the
	# documented contract is to return undef, so a logger must never be
	# allowed to turn a warning or a handled error into an exception.
	eval { $self->{'logger'}->error($message) } if ref($self) && $self->{'logger'};

	return $self;
}

# ---------------------------------------------------------------------------
# _croak / _carp -- raise a translated error or warning
#
# Purpose:     One place that looks up the message, logs it and hands it to
#              Carp, so that every diagnostic is translatable and logged alike.
#              Carp reports the caller's location, not ours, because it skips
#              frames inside this package.
# Entry:       $self -- object or class name
#              $key  -- message key (see i18n())
#              $args -- optional hashref of placeholder values
# Exit:        _croak never returns; _carp returns $self
# Side effects: logs via the logger if there is one; writes to STDERR (_carp)
# ---------------------------------------------------------------------------
sub _croak :Protected {
	my ($self, $key, $args) = @_;

	my $message = $self->i18n($key, { class => (ref($self) || $self), %{$args || {}} });
	$self->_log_error($message);
	Carp::croak($message);
}

sub _carp :Protected {
	my ($self, $key, $args) = @_;

	my $message = $self->i18n($key, { class => (ref($self) || $self), %{$args || {}} });
	$self->_log_error($message);
	Carp::carp($message);

	return $self;
}

# ---------------------------------------------------------------------------
# _clone -- copy an object, overriding some of its fields
#
# Purpose:     Support $meteo->new(host => ...) for cheap test variants.
# Entry:       $self   -- Weather::Meteo object to copy
#              $params -- hashref of overrides; ua => undef means "keep the old UA"
# Exit:        a new object of the same class
# Side effects: croaks if the replacement ua cannot get()
# ---------------------------------------------------------------------------
sub _clone :Protected {
	my ($self, $params) = @_;

	if(exists($params->{ua})) {
		if(!defined($params->{ua})) {
			delete $params->{ua};
		} elsif(!Scalar::Util::blessed($params->{ua}) || !$params->{ua}->can('get')) {
			$self->_croak('bad_ua');
		}
	}

	return bless { %{$self}, %{$params} }, ref($self);
}

# ---------------------------------------------------------------------------
# _untaint_param -- validate one constructor argument and replace it by its
#                   untainted capture
#
# Purpose:     Stop hostile values (SSRF in host, absurd retry counts) at the
#              door, and satisfy taint mode.
# Entry:       $class  -- class name, used to raise the error
#              $params -- hashref of constructor arguments (modified)
#              $name   -- key to check; must be in %PARAM_PATTERNS
# Exit:        nothing useful
# Side effects: croaks if the value does not match; rewrites $params->{$name}
# ---------------------------------------------------------------------------
sub _untaint_param :Private {
	my ($class, $params, $name) = @_;
	my ($pattern, $key) = @{ $PARAM_PATTERNS{$name} };

	my ($safe) = ($params->{$name} =~ $pattern);
	$class->_croak($key, { value => $params->{$name} }) unless defined($safe);
	$params->{$name} = $safe;

	return;
}

# ---------------------------------------------------------------------------
# _location_params -- turn any of the accepted call forms into one hashref
#
# Purpose:     weather(), forecast() and sunrise_sunset() all accept a hashref,
#              a flat list, or (Geo::Location::Point, $second_value).  Doing
#              that once keeps the three methods identical in how they read
#              their arguments.
# Entry:       $args       -- arrayref of the caller's arguments
#              $second_key -- name for the optional second positional value
#              $min_args   -- fewest arguments the positional form takes
#              $max_args   -- most arguments it takes; more means a different call
#                             form (which Params::Get will then reject)
# Exit:        hashref of named parameters
# Side effects: none; tz comes from the location only when TIMEZONEDB_KEY is set
#               because that is when Geo::Location::Point can look it up
# ---------------------------------------------------------------------------
sub _location_params :Protected {
	my ($self, $args, $second_key, $min_args, $max_args) = @_;
	my $first = $args->[0];
	my $params;

	if(@{$args} >= $min_args && @{$args} <= $max_args && Scalar::Util::blessed($first) && $first->can('latitude')) {
		$params = { latitude => $first->latitude(), longitude => $first->longitude() };
		$params->{$second_key} = $args->[1] if defined($args->[1]);
		$params->{tz}          = $first->tz() if $first->can('tz') && $ENV{'TIMEZONEDB_KEY'};
	} else {
		$params = Params::Get::get_params(undef, $args);
	}

	return $params;
}

# ---------------------------------------------------------------------------
# _coordinates -- find, check and clean the latitude and longitude
#
# Purpose:     One implementation of coordinate handling for all three data
#              methods (it used to be copied into each).
# Entry:       $params    -- hashref from _location_params()
#              $usage_key -- message key to croak with if something is missing
#              @required  -- further keys of $params that must be present
# Exit:        arrayref [ $latitude, $longitude ], validated and untainted
# Side effects: croaks on missing arguments or malformed coordinates
# ---------------------------------------------------------------------------
sub _coordinates :Protected {
	my ($self, $params, $usage_key, @required) = @_;
	my ($latitude, $longitude, $location) = @{$params}{qw(latitude longitude location)};

	# A location object can stand in for explicit coordinates
	if(!defined($latitude) && Scalar::Util::blessed($location) && $location->can('latitude')) {
		($latitude, $longitude) = ($location->latitude(), $location->longitude());
	}

	if(!defined($latitude) || !defined($longitude) || grep { !defined($params->{$_}) } @required) {
		$self->_croak($usage_key);
	}

	my @normalised = map { _normalise_coord($_) } ($latitude, $longitude);
	my @clean      = map { $_ =~ $COORD_RE ? $1 : undef } @normalised;

	if(grep { !defined } @clean) {
		$self->_croak('invalid_coordinates', { latitude => $normalised[0], longitude => $normalised[1] });
	}

	return \@clean;
}

# ---------------------------------------------------------------------------
# _archive_date -- turn the caller's date into YYYY-MM-DD for the archive
#
# Purpose:     Accept a string or any strftime-capable object, and filter out
#              dates the archive cannot hold.
# Entry:       $date -- string or object with strftime()
# Exit:        'YYYY-MM-DD', or undef if the date is before 1940 (silently) or
#              not a date at all (with a warning)
# Side effects: carps for unparseable strings; croaks if the date looks like
#               one but is not YYYY-MM-DD
# ---------------------------------------------------------------------------
sub _archive_date :Protected {
	my ($self, $date) = @_;
	my $result;

	if(Scalar::Util::blessed($date) && $date->can('strftime')) {
		$date = $date->strftime('%F');
	} elsif($date !~ /\A\d{4}-/) {
		$self->_carp('not_a_date', { date => $date });
		return;
	}

	# The year test comes first so that pre-1940 input is always quietly
	# undef, whether it came as a string or as an object.
	my ($year) = ($date =~ /\A(\d{4})-/);
	if(!defined($year) || $year >= $FIRST_YEAR) {
		($result) = ($date =~ $DATE_RE);
		$self->_croak('invalid_date_format') unless defined($result);
	}

	return $result;
}

# ---------------------------------------------------------------------------
# _report_query -- the query parameters shared by weather() and forecast()
#
# Purpose:     Both endpoints return the same hourly/daily structure, so they
#              must request the same fields in the same units.
# Entry:       $latitude, $longitude, $tz -- already validated
#              $extra -- arrayref of endpoint-specific key/value pairs
# Exit:        arrayref of key/value pairs, order preserved for stable URLs
# Side effects: none
# ---------------------------------------------------------------------------
sub _report_query :Private {
	my ($latitude, $longitude, $tz, $extra) = @_;

	return [
		latitude  => $latitude,
		longitude => $longitude,
		@{$extra},
		hourly    => $HOURLY_FIELDS,
		daily     => $DAILY_FIELDS,
		timezone  => $tz,
		@UNIT_PAIRS,
	];
}

# ---------------------------------------------------------------------------
# _build_url -- assemble an API URL
#
# Purpose:     Build the URL and keep commas readable; URI would otherwise
#              encode them as %2C, which the API accepts but humans cannot read
#              in logs.
# Entry:       $host  -- validated hostname
#              $path  -- endpoint path
#              $pairs -- arrayref of key/value query pairs
# Exit:        URL string
# Side effects: none
# ---------------------------------------------------------------------------
sub _build_url :Private {
	my ($host, $path, $pairs) = @_;

	my $uri = URI->new("https://$host$path");
	$uri->query_form(@{$pairs});
	(my $url = $uri->as_string()) =~ s/%2C/,/g;

	return $url;
}

# ---------------------------------------------------------------------------
# _first_element -- the first entry of a named array inside a hashref
#
# Purpose:     The API wraps single-day answers in one-element arrays, and a
#              broken response may lack the array altogether.
# Entry:       $hash -- hashref or anything else
#              $key  -- name of the array
# Exit:        the first element, or undef if there is none
# Side effects: none
# ---------------------------------------------------------------------------
sub _first_element :Private {
	my ($hash, $key) = @_;

	return (ref($hash) eq 'HASH' && ref($hash->{$key}) eq 'ARRAY') ? $hash->{$key}[0] : undef;
}

# ---------------------------------------------------------------------------
# _normalise_coord -- fix a coordinate that leads with a bare decimal point
#
# Purpose:     Perl and many user inputs write ".5" where "0.5" is required.
#              The coordinate pattern rejects the bare-dot form, so we
#              normalise before validating.
# Entry:       $coord -- a coordinate string, possibly with a leading "."
# Exit:        normalised string: ".5" -> "0.5", "-.5" -> "-0.5", others unchanged
# Side effects: none
# ---------------------------------------------------------------------------
sub _normalise_coord :Private {
	my $result = $_[0];

	# Anchored with \z; atomic group on \d+ prevents O(n) backtracking
	if(my ($frac) = $result =~ /\A-\.((?>\d+))\z/) { $result = "-0.$frac" }
	elsif($result =~ /\A\./)                         { $result = "0$result" }

	return $result;
}

# ---------------------------------------------------------------------------
# _enforce_rate_limit -- sleep until enough time has passed since the last call
#
# Purpose:     Prevent hammering the API when min_interval > 0.  Uses
#              high-resolution time: whole-second time() could under- or
#              over-sleep by nearly a second.
# Entry:       $self -- Weather::Meteo instance with last_request and min_interval
# Exit:        $self
# Side effects: may block for up to min_interval seconds via Time::HiRes::sleep
# ---------------------------------------------------------------------------
sub _enforce_rate_limit :Protected {
	my $self    = $_[0];
	my $elapsed = Time::HiRes::time() - $self->{last_request};

	Time::HiRes::sleep($self->{min_interval} - $elapsed) if $elapsed < $self->{min_interval};

	return $self;
}

# ---------------------------------------------------------------------------
# _backoff_seconds -- how long to wait before the next retry
#
# Purpose:     Exponential backoff, unless the server said how long to wait.
# Entry:       $res        -- the failed HTTP::Response
#              $attempt    -- 0 for the first retry, 1 for the second, ...
#              $base_delay -- seconds before the first retry
# Exit:        seconds to wait, never more than $MAX_RETRY_WAIT
# Side effects: none
# ---------------------------------------------------------------------------
sub _backoff_seconds :Private {
	my ($res, $attempt, $base_delay) = @_;

	# Only the numeric (delta-seconds) form of Retry-After is honoured; the
	# HTTP-date form would need clock agreement with the server.
	my ($retry_after) = (($res->header('Retry-After') // '') =~ /\A(\d{1,6})\z/);
	my $wait = $retry_after // ($base_delay * (2 ** $attempt));

	return $wait > $MAX_RETRY_WAIT ? $MAX_RETRY_WAIT : $wait;
}

# ---------------------------------------------------------------------------
# _get_with_retry -- GET a URL, retrying transient failures
#
# Purpose:     Ride out rate limiting (429) and brief outages (502-504).
# Entry:       $self -- object; honours max_retries, retry_delay, min_interval
#              $url  -- fully-formed request URL
# Exit:        the last HTTP::Response (or whatever the UA returned)
# Side effects: sleeps between attempts; updates last_request
# ---------------------------------------------------------------------------
sub _get_with_retry :Protected {
	my ($self, $url) = @_;
	my $max_retries = $self->{max_retries} // $MAX_RETRIES;
	my $base_delay  = $self->{retry_delay} // $RETRY_DELAY;
	my $res;

	foreach my $attempt (0 .. $max_retries) {
		$self->_enforce_rate_limit();
		$res = $self->{ua}->get($url);
		$self->{last_request} = Time::HiRes::time();

		last unless _is_retryable($res) && $attempt < $max_retries;

		my $wait = _backoff_seconds($res, $attempt, $base_delay);
		Time::HiRes::sleep($wait) if $wait > 0;
	}

	return $res;
}

# ---------------------------------------------------------------------------
# _is_retryable -- is this response worth another attempt?
#
# Purpose:     Keep the list of transient statuses in one place (%RETRYABLE_STATUS).
# Entry:       $res -- anything the UA returned
# Exit:        true for an HTTP error response with a transient status
# Side effects: none
# ---------------------------------------------------------------------------
sub _is_retryable :Private {
	my $res = $_[0];

	return Scalar::Util::blessed($res) && $res->can('is_error') && $res->is_error()
		&& $RETRYABLE_STATUS{ $res->code() };
}

# ---------------------------------------------------------------------------
# _fetch_json -- HTTP GET a URL and decode the response body as JSON
#
# Purpose:     Centralise the HTTP dispatch and JSON parsing steps that are
#              common to all three public data methods, giving one place to
#              maintain error-handling and rate-limiting logic.
# Entry:       $self -- Weather::Meteo instance
#              $url  -- fully-formed request URL string
# Exit:        decoded JSON value on success; undef on error
# Side effects: enforces rate limit (may sleep); updates last_request timestamp;
#              carps on HTTP errors and JSON parse failures
# ---------------------------------------------------------------------------
sub _fetch_json :Protected {
	my ($self, $url) = @_;
	my $res = $self->_get_with_retry($url);
	my $decoded;

	if(!(Scalar::Util::blessed($res) && $res->can('is_error'))) {
		$self->_carp('bad_response');
	} elsif($res->is_error()) {
		$self->_carp('http_error', { url => $url, status => $res->status_line() });
	} else {
		# charset 'none' leaves the bytes alone: JSON is UTF-8 by definition
		# and the decoder below does that conversion itself.
		eval { $decoded = JSON::MaybeXS->new()->utf8()->decode($res->decoded_content(charset => 'none')) };
		if($@) {
			# Strip control characters and cap the length so that a hostile
			# response body cannot inject log lines or flood the log.
			(my $error = "$@") =~ s/[[:cntrl:]]/ /g;
			$error = substr($error, 0, 200) . '...' if length($error) > 200;
			$self->_carp('json_parse', { error => $error });
		}
	}

	return $decoded;
}

# ---------------------------------------------------------------------------
# _api_get -- fetch a URL and return the response if the API accepted it
#
# Purpose:     Open-Meteo reports some failures as HTTP 200 with
#              {"error":true,"reason":"..."}; treat those as failures too.
# Entry:       $self, $url
# Exit:        hashref, or undef on any failure
# Side effects: as _fetch_json; also carps with the API's reason
# ---------------------------------------------------------------------------
sub _api_get :Protected {
	my ($self, $url) = @_;
	my $rc     = $self->_fetch_json($url);
	my $result = undef;

	if(ref($rc) eq 'HASH') {
		if($rc->{'error'}) {
			# Surface the API-provided reason so callers can diagnose failures
			$self->_carp('api_error', { reason => $rc->{'reason'} // 'unknown' });
		} else {
			$result = $rc;
		}
	}

	return $result;
}

# ---------------------------------------------------------------------------
# _cached_report -- fetch an hourly/daily report, using the cache
#
# Purpose:     weather() and forecast() differ only in the URL and cache key.
# Entry:       $self, $cache_key, $url
# Exit:        hashref with an 'hourly' key, or undef
# Side effects: reads and writes the cache; makes an HTTP request on a miss
# ---------------------------------------------------------------------------
sub _cached_report :Protected {
	my ($self, $cache_key, $url) = @_;
	my $report = $self->{'cache'}->get($cache_key);

	if(!$report) {
		my $rc = $self->_api_get($url);
		if(defined($rc) && defined($rc->{'hourly'})) {
			$self->{'cache'}->set($cache_key, $rc);
			$report = $rc;
		}
	}

	return $report ? Return::Set::set_return($report, { type => 'hashref', min => 1 }) : undef;
}

=head1 LIMITATIONS

=over 4

=item * Archive data lag

The Open-Meteo archive endpoint has a lag of approximately five days before
recent historical data becomes available.
For dates within the past five days,
C<weather()> may return C<undef> even when no error occurs.
Use C<forecast()> or C<sunrise_sunset()> (without a date) to obtain data for
today or recent days.

=item * Coordinate range

The module normalises coordinates with a bare leading decimal point (e.g.
C<".5"> to C<"0.5">) but does not validate that latitude is within C<-90..90>
or longitude within C<-180..180>.
Out-of-range values are passed to the API, which may return an error.

=item * No sub-hourly resolution

The hourly data arrays always contain exactly 24 entries per day (one per hour).
Sub-hourly resolution is not supported by this interface.

=item * Per-process rate limiting

The C<min_interval> rate limiter tracks the last request timestamp within a
single process instance.
Multiple concurrent processes or threads are not coordinated and may collectively
exceed the desired request rate.

=item * Timezone resolution requires an API key

Automatic per-location timezone resolution requires setting the
C<TIMEZONEDB_KEY> environment variable to a valid key from
L<https://timezonedb.com>.
Without it the module defaults to C<Europe/London> for all locations.

=item * No list-context support

C<weather()> and C<forecast()> enforce scalar/hashref context via
L<Return::Set>.
List context is not currently supported.

=item * Access control is enforced, but only by convention for subclasses

Helper functions with no need of an object (coordinate and URL handling, retry
arithmetic) are L<Sub::Private> and cannot be called, overridden or mocked from
outside this file.
Helper methods that need the object are L<Sub::Protected>: callable from this
class and its subclasses but not from unrelated code.
White-box tests therefore have to go through the public methods or subclass
C<Weather::Meteo>.

Both modules switch their checks off when C<$ENV{HARNESS_ACTIVE}> is set,
which C<prove> and C<make test> do, so under a test harness the helpers can be
called from anywhere.
Set C<$Sub::Private::config{harness_bypass}> and
C<$Sub::Protected::config{harness_bypass}> to C<0> to test the enforcement
itself, as F<t/i18n.t> does.
Also note that L<Sub::Protected> registers the C<:Protected> attribute in
C<UNIVERSAL>, so it is available to every package in the process once this
module is loaded.
The cost of this strictness is that a subclass can reuse the protected methods
but not the private functions, so it cannot change, for example, how URLs are built.

=item * Errors are reported as C<undef> plus a warning

Every failure of C<weather()>, C<forecast()> and C<sunrise_sunset()> that is not
a usage error comes back as C<undef> with a C<carp>.
A caller therefore cannot tell a rate limit from an outage from an unknown
place without parsing the warning text.
This is the documented contract, kept for compatibility, but an exception
class (or at least a C<last_error()> accessor) would be a better design.

=item * Retries block the caller

Retrying a transient failure sleeps in the calling process, for up to
C<max_retries> times the (doubling, capped) delay: about 7 seconds with the
defaults.
Set C<max_retries> to C<0> for a non-blocking client, or do the retrying
yourself.

=item * Messages are translatable, but the plural rules are not

L</i18n> understands C<one> and C<other> only, which is right for English,
German and French but not for languages with several plural forms.
It also does not translate strings that come from outside the module, such as
the text of an HTTP status line or an exception from the JSON decoder.

=item * Dates are checked by shape, not by calendar

C<2022-02-31> and C<2022-13-45> have the shape C<YYYY-MM-DD> and are passed to
the API, which rejects them.
The module does not check them itself because no calendar module is a
dependency.

=item * "Today" is the host's date, not the location's

When C<sunrise_sunset()> is called without a date, or with today's date, "today"
is taken from the local clock of the machine running the code, not from the
C<tz> requested.
Near midnight and for distant time zones that can be a day out.

=item * Cache keys use the text of the coordinates

C<51.34> and C<51.340> are cached separately, and so are C<tz> spellings that
the API treats as the same zone.
The results are correct; only the hit rate suffers.

=item * Host parameter restricted to plain DNS hostnames

The C<host> constructor parameter (and the C<WEATHER__METEO__host> environment
variable) must match C</\A[A-Za-z0-9][A-Za-z0-9.\-]*(:\d{1,5})?\z/>.
IP addresses in CIDR notation, URLs with path components, C<@>-style
user-info, and other special characters are rejected with a C<croak> to
prevent Server-Side Request Forgery.
If you need to test against a local service on a non-standard port, use a
plain C<hostname:port> string (e.g. C<localhost:8080>).

=item * Coordinate values limited to decimal numbers

Latitude and longitude must match C</\A-?(?>\d+)(?:\.(?>\d+))?\z/> after
leading-decimal normalisation.
Exponential notation (C<1.5e2>), hex (C<0x1F>), and strings with embedded
whitespace are rejected.
Pass a pre-formatted decimal string rather than a Perl numeric expression if
your caller might produce non-decimal representations.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh@nigelhorne.com> >>

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License, version 2.
See L</LICENSE AND COPYRIGHT> below.

Lots of thanks to the folks at L<https://open-meteo.com>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-weather-meteo at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-Meteo>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

=over 4

=item * Open Meteo API: L<https://open-meteo.com/en/docs#api_form>

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Weather-Meteo/coverage/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Weather::Meteo

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Weather-Meteo>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Weather-Meteo>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Weather-Meteo>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Weather-Meteo>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Weather-Meteo>

=back

=head1 FORMAL SPECIFICATION

=head2 new

    ___ NEW ___________________________________________________
    | class?        : PACKAGE | Weather::Meteo               |
    | params?       : NAME |--> VALUE                         |
    |___________________________________________________________|
    | result!       : Weather::Meteo                          |
    |                                                          |
    | blessed(result!) = 'Weather::Meteo'                     |
    |                                                          |
    | params?.ua?    => result!.ua    = params?.ua             |
    | ~params?.ua    => result!.ua    : LWP::UserAgent         |
    | params?.cache? => result!.cache = params?.cache          |
    | ~params?.cache => result!.cache : CHI(Memory, global)    |
    | params?.host? ^ valid_hostname(params?.host?)             |
    |   => result!.host = params?.host?                        |
    | params?.host? ^ ~valid_hostname(params?.host?)           |
    |   => croak /Invalid host/                                |
    |   valid_hostname(h) ::= h =~ /\A[A-Za-z0-9][A-Za-z0-9.\-]*(:\d{1,5})?\z/ |
    | ~params?.host? => result!.host  = DEFAULT_HOST           |
    | params?.max_retries? ^ ~(params?.max_retries? =~ /\A\d{1,3}\z/) |
    |   => croak /Invalid max_retries/                         |
    | params?.retry_delay? ^ ~(params?.retry_delay? =~ /\A\d{1,4}(\.\d{1,3})?\z/) |
    |   => croak /Invalid retry_delay/                         |
    | params?.messages? ^ ~hashref(params?.messages?)         |
    |   => croak /'messages' argument must be a hash reference/ |
    | params?.min_interval? => result!.min_interval = params?.min_interval |
    | ~params?.min_interval => result!.min_interval = 0        |
    | result!.last_request  = 0                                |
    |___________________________________________________________|
    |                                                          |
    | PRE:  class? is PACKAGE name or blessed Weather::Meteo  |
    | POST: blessed(result!) = 'Weather::Meteo'               |
    |       forall k in params? . result!.k = params?.k       |
    |___________________________________________________________|

=head2 weather

    ___ WEATHER _______________________________________________
    | self?      : Weather::Meteo                            |
    | latitude?  : REAL                                       |
    | longitude? : REAL                                       |
    | date?      : DATE_STRING | strftime_OBJECT              |
    | tz?        : STRING  (optional, default 'Europe/London')|
    |____________________________________________________________|
    | result!    : HASHREF | undef                            |
    |____________________________________________________________|
    |                                                          |
    | PRE (~latitude? v ~longitude? v ~date?)                 |
    |   => croak /Usage: weather\(latitude/                   |
    |                                                          |
    | PRE lat? or lon? not matching                            |
    |     /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/                     |
    |   (after leading-decimal normalisation via _normalise_coord) |
    |   => croak /Invalid latitude\/longitude format/          |
    |   NOTE: list-context capture untaints lat/lon (perl -T) |
    |         atomic groups eliminate O(n) backtracking        |
    |                                                          |
    | PRE date? blessed ^ date?.can('strftime')               |
    |   => date? := date?.strftime('%F')                       |
    |   PRE date? !~ /\A\d{4}-\d{2}-\d{2}\z/                 |
    |     => croak /Invalid date format. Expected YYYY-MM-DD/ |
    |                                                          |
    | PRE year(date?) < 1940   (string or strftime object)    |
    |   => result! = undef                                     |
    |                                                          |
    | POST cache hit for (lat, lon, date, tz)                 |
    |   => result! = cached_value                              |
    |                                                          |
    | POST HTTP error response                                 |
    |   => carp msg ^ result! = undef                          |
    |                                                          |
    | POST JSON parse failure                                  |
    |   => carp /Failed to parse JSON response/ ^ result! = undef |
    |                                                          |
    | POST response.error = true                               |
    |   => carp /API error: reason/ ^ result! = undef          |
    |                                                          |
    | POST ~response.hourly                                    |
    |   => result! = undef                                     |
    |                                                          |
    | POST otherwise                                           |
    |   => result! = { hourly => HOURLY, daily => DAILY }     |
    |      cache.set(key, result!)                             |
    |____________________________________________________________|

=head2 forecast

    ___ FORECAST ______________________________________________
    | self?      : Weather::Meteo                            |
    | latitude?  : REAL                                       |
    | longitude? : REAL                                       |
    | days?      : INTEGER [1..16]  (optional, default 7)    |
    | tz?        : STRING  (optional, default 'Europe/London')|
    |____________________________________________________________|
    | result!    : HASHREF | undef                            |
    |____________________________________________________________|
    |                                                          |
    | PRE (~latitude? v ~longitude?)                           |
    |   => croak /Usage: forecast\(latitude/                  |
    |                                                          |
    | PRE lat? or lon? not matching                            |
    |     /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/                     |
    |   (after leading-decimal normalisation via _normalise_coord) |
    |   => croak /Invalid latitude\/longitude format/          |
    |   NOTE: list-context capture untaints lat/lon (perl -T) |
    |         atomic groups eliminate O(n) backtracking        |
    |                                                          |
    | PRE days? defined ^ (days? < 1 v days? > 16)            |
    |   => carp /days must be between 1 and 16/               |
    |      days? := 7                                          |
    |                                                          |
    | POST cache hit for (lat, lon, days, tz)                 |
    |   => result! = cached_value                              |
    |                                                          |
    | POST HTTP error response                                 |
    |   => carp msg ^ result! = undef                          |
    |                                                          |
    | POST JSON parse failure                                  |
    |   => carp /Failed to parse JSON response/ ^ result! = undef |
    |                                                          |
    | POST response.error = true                               |
    |   => result! = undef                                     |
    |                                                          |
    | POST ~response.hourly                                    |
    |   => result! = undef                                     |
    |                                                          |
    | POST otherwise                                           |
    |   => result! = { hourly => HOURLY, daily => DAILY }     |
    |      cache.set(key, result!)                             |
    |____________________________________________________________|

=head2 sunrise_sunset

    ___ SUNRISE_SUNSET ________________________________________
    | self?      : Weather::Meteo                            |
    | latitude?  : REAL                                       |
    | longitude? : REAL                                       |
    | date?      : DATE_STRING  (optional, default today)     |
    | tz?        : STRING  (optional, default 'Europe/London')|
    |____________________________________________________________|
    | result!    : HASHREF | undef                            |
    |____________________________________________________________|
    |                                                          |
    | PRE (~latitude? v ~longitude?)                           |
    |   => croak /Usage: sunrise_sunset\(latitude/            |
    |                                                          |
    | PRE lat? or lon? not matching                            |
    |     /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/                     |
    |   (after leading-decimal normalisation via _normalise_coord) |
    |   => croak /Invalid latitude\/longitude format/          |
    |   NOTE: list-context capture untaints lat/lon (perl -T) |
    |         atomic groups eliminate O(n) backtracking        |
    |                                                          |
    | PRE date? defined ^ date? !~ /\A\d{4}-\d{2}-\d{2}\z/   |
    |   => carp /not a valid date/ ^ result! = undef           |
    |                                                          |
    | POST ~date? v date? >= today                             |
    |   => uses forecast endpoint (api.open-meteo.com)        |
    |                                                          |
    | POST date? < today                                       |
    |   => uses archive endpoint (archive-api.open-meteo.com) |
    |                                                          |
    | POST cache hit for (lat, lon, date, tz)                 |
    |   => result! = cached_value                              |
    |                                                          |
    | POST HTTP error or JSON failure or ~daily.sunrise        |
    |   => result! = undef                                     |
    |                                                          |
    | POST otherwise                                           |
    |   => result! = { sunrise => ISO8601, sunset => ISO8601 } |
    |      cache.set(key, result!)                             |
    |____________________________________________________________|

=head2 ua

    ___ UA ____________________________________________________
    | self?   : Weather::Meteo                               |
    | ua?     : OBJECT [can 'get']   (optional)              |
    |____________________________________________________________|
    | result! : OBJECT [can 'get']                            |
    |____________________________________________________________|
    |                                                          |
    | PRE ua? defined ^ ~ua?.can('get')                       |
    |   => croak /must be an object that understands the get method/ |
    |                                                          |
    | POST ua? defined                                         |
    |   => self?.ua = ua? ^ result! = ua?                     |
    |                                                          |
    | POST ~ua?                                                |
    |   => result! = self?.ua  (no state change)              |
    |____________________________________________________________|

=head2 i18n

    ___ I18N __________________________________________________
    | self?  : Weather::Meteo | PACKAGE                      |
    | key?   : STRING                                         |
    | args?  : NAME |--> VALUE   (optional, default empty)    |
    |____________________________________________________________|
    | result! : STRING                                        |
    |____________________________________________________________|
    |                                                          |
    | format == self?.messages(key?)  if defined               |
    |        == BUILTIN(key?)         otherwise                |
    |                                                          |
    | ~defined(format) => confess /no message defined for key/ |
    |                                                          |
    | format : HASHREF                                         |
    |   => format := variant(format, args?.count, args?.gender)|
    |      variant prefers  <cat>_<gender>, then <cat>, then   |
    |      other;  cat = 'one' if count = 1 else 'other'       |
    |                                                          |
    | args?.sprintf : ARRAY                                    |
    |   => format := sprintf(format, args?.sprintf)            |
    |                                                          |
    | result! = format with every {n} in dom(args?) replaced  |
    |           by args?.n   (undef becomes the empty string;  |
    |           names not in dom(args?) are left as {n})       |
    |____________________________________________________________|

=head1 LICENSE AND COPYRIGHT

Copyright 2023-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
