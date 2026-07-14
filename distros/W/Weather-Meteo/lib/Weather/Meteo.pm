package Weather::Meteo;

use strict;
use warnings;

use Carp;
use CHI;
use JSON::MaybeXS;
use LWP::UserAgent;
use Object::Configure;
use Params::Get 0.13;
use Params::Validate::Strict;
use Return::Set;
use Scalar::Util;
use Time::HiRes;
use URI;

# Archive API host (historical data from 1940 onwards)
use constant DEFAULT_HOST  => 'archive-api.open-meteo.com';
# Forecast API host (up to 16 days ahead)
use constant FORECAST_HOST => 'api.open-meteo.com';
use constant FIRST_YEAR    => 1940;
use constant EXPIRES_IN    => '1 hour';
use constant MIN_INTERVAL  => 0;
# Default timezone when neither the caller nor the location object supplies one
use constant DEFAULT_TZ    => 'Europe/London';

=head1 NAME

Weather::Meteo - Interface to L<https://open-meteo.com> for historical and forecast weather data

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';

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

=item * C<min_interval>

Minimum number of seconds to wait between API requests.
Defaults to C<0> (no delay).
Use this option to enforce rate-limiting.

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

=cut

sub new {
	my $class = shift;
	my $params = Params::Get::get_params(undef, \@_) || {};

	if(!defined($class)) {
		# Weather::Meteo::new() used rather than Weather::Meteo->new()
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# Clone path: merge new params over the existing object's fields.
		if(exists($params->{ua})) {
			if(!defined($params->{ua})) {
				# ua=>undef means "keep the original" -- silently drop it
				delete $params->{ua};
			} elsif(!Scalar::Util::blessed($params->{ua}) || !$params->{ua}->can('get')) {
				Carp::croak("'ua' argument must be an object with a get() method");
			}
		}
		return bless { %{$class}, %{$params} }, ref($class);
	}

	$params = Object::Configure::configure($class, $params);

	# Validate and untaint host: only DNS labels + optional port are accepted.
	# Prevents SSRF via WEATHER__METEO__host env var or config file injection.
	# Falsy values (undef, "", 0) are left as-is -- they fall back to DEFAULT_HOST
	# in the bless statement and never reach the URL constructor.
	if($params->{host}) {
		(my $safe_host) = ($params->{host} =~ /\A([A-Za-z0-9][A-Za-z0-9.\-]*(:\d{1,5})?)\z/)
			or Carp::croak("Invalid host '$params->{host}': must be a plain hostname");
		$params->{host} = $safe_host;
	}

	my $ua = $params->{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
	}

	my $cache = $params->{cache} || CHI->new(
		driver     => 'Memory',
		global     => 1,
		expires_in => EXPIRES_IN,
	);

	return bless {
		min_interval => $params->{min_interval} || MIN_INTERVAL,
		last_request => 0,
		%{$params},
		cache => $cache,
		host  => $params->{host} || DEFAULT_HOST,
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
    Invalid date format. Expected YYYY-MM-DD             croak  strftime() returned wrong format
    UA->get did not return a valid HTTP response         carp   UA returned non-response object
    $url API returned error: $status                     carp   HTTP 4xx/5xx response
    Failed to parse JSON response: $err                  carp   response body is not valid JSON
                                                               ($err is the exception with control
                                                               chars stripped and length capped at
                                                               200 chars to prevent log injection)
    Weather::Meteo: API error: $reason                   carp   API returned {"error":true,...}

=head3 PSEUDOCODE

    parse call form (3 variants: hashref, flat list, positional (location, date))
    extract lat, lon, date, tz; resolve location object if given
    croak if lat, lon, or date is missing
    normalise leading-decimal coordinates via _normalise_coord()
    validate coordinates with /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/
      (atomic groups prevent ReDoS; list-context capture also untaints for perl -T)
    croak if either coordinate does not match
    if date is a strftime object: call strftime('%F'); croak if result not YYYY-MM-DD
    return undef silently if year < 1940
    carp and return undef if date string is not YYYY-MM-DD
    return cached result if available
    build URL for /v1/archive endpoint with hourly and daily fields
    fetch and decode JSON via _fetch_json()
    return undef if HTTP error, JSON error, or API-level error (with carp)
    return undef if response has no 'hourly' key
    store result in cache
    return hashref (enforced by Return::Set)

=cut

sub weather
{
	my $self = shift;
	my $params;

	if((scalar(@_) == 2) && Scalar::Util::blessed($_[0]) && ($_[0]->can('latitude'))) {
		# Two-arg positional form: (location_obj, date)
		my $location = $_[0];
		$params = {
			latitude  => $location->latitude(),
			longitude => $location->longitude(),
			date      => $_[1],
		};
		$params->{'tz'} = $_[0]->tz()
			if $_[0]->can('tz') && $ENV{'TIMEZONEDB_KEY'};
	} else {
		$params = Params::Get::get_params(undef, \@_);
	}

	my $latitude  = $params->{latitude};
	my $longitude = $params->{longitude};
	my $location  = $params->{'location'};
	my $date      = $params->{'date'};
	my $tz        = $params->{'tz'} || DEFAULT_TZ;

	if(!defined($latitude) && defined($location) &&
	   Scalar::Util::blessed($location) && $location->can('latitude')) {
		$latitude  = $location->latitude();
		$longitude = $location->longitude();
	}

	if(!defined($latitude) || !defined($longitude) || !defined($date)) {
		my $msg = 'Usage: weather(latitude => $latitude, longitude => $longitude, date => "YYYY-MM-DD")';
		$self->{'logger'}->error($msg) if $self->{'logger'};
		Carp::croak($msg);
	}

	$latitude  = _normalise_coord($latitude);
	$longitude = _normalise_coord($longitude);

	# Atomic groups prevent O(n) backtracking on adversarial input; list-context
	# capture also untaints the values for taint-mode compliance.
	my ($lat_clean) = ($latitude  =~ /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/);
	my ($lon_clean) = ($longitude =~ /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/);
	if(!defined($lat_clean) || !defined($lon_clean)) {
		my $msg = __PACKAGE__ . ": Invalid latitude/longitude format ($latitude, $longitude)";
		$self->{'logger'}->error($msg) if $self->{'logger'};
		Carp::croak($msg);
	}
	$latitude  = $lat_clean;
	$longitude = $lon_clean;

	if(Scalar::Util::blessed($date) && $date->can('strftime')) {
		$date = $date->strftime('%F');
	} elsif($date =~ /^(\d{4})-/) {
		return if $1 < FIRST_YEAR;
	} else {
		Carp::carp("'$date' is not a valid date");
		return;
	}

	unless($date =~ /^\d{4}-\d{2}-\d{2}$/) {
		my $msg = 'Invalid date format. Expected YYYY-MM-DD';
		$self->{'logger'}->error($msg) if $self->{'logger'};
		Carp::croak($msg);
	}

	my $cache_key = "weather:$latitude:$longitude:$date:$tz";
	if(my $cached = $self->{'cache'}->get($cache_key)) {
		return $cached;
	}

	my $uri = URI->new("https://$self->{host}/v1/archive");
	$uri->query_form(
		latitude           => $latitude,
		longitude          => $longitude,
		start_date         => $date,
		end_date           => $date,
		hourly             => 'temperature_2m,rain,snowfall,weathercode',
		daily              => 'weathercode,temperature_2m_max,temperature_2m_min,rain_sum,snowfall_sum,precipitation_hours,windspeed_10m_max,windgusts_10m_max,sunrise,sunset',
		timezone           => $tz,
		# https://stackoverflow.com/questions/16086962/how-to-get-a-time-zone-from-a-location-using-latitude-and-longitude-coordinates
		windspeed_unit     => 'mph',
		precipitation_unit => 'inch',
	);
	my $url = $uri->as_string();
	$url =~ s/%2C/,/g;

	my $rc = $self->_fetch_json($url);
	return unless defined($rc) && ref($rc) eq 'HASH';

	if($rc->{'error'}) {
		# Surface the API-provided reason so callers can diagnose failures
		my $reason = $rc->{'reason'} // 'unknown';
		# eval guard: logger->error() may be fatal (e.g. Log::Abstraction), but
		# the documented contract is to return undef, so we must not propagate the die
		eval { $self->{'logger'}->error(__PACKAGE__ . ": API error: $reason") } if $self->{'logger'};
		Carp::carp(__PACKAGE__ . ": API error: $reason");
		return;
	}

	return unless defined($rc->{'hourly'});

	$self->{'cache'}->set($cache_key, $rc);
	return Return::Set::set_return($rc, { type => 'hashref', min => 1 });
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

=head3 PSEUDOCODE

    parse call form (3 variants: hashref, flat list, positional (location) or (location, days))
    extract lat, lon, days, tz; resolve location object if given
    croak if lat or lon is missing
    normalise leading-decimal coordinates via _normalise_coord()
    validate coordinates with /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/
      (atomic groups prevent ReDoS; list-context capture also untaints for perl -T)
    croak if either coordinate does not match
    clamp days to 1-16: carp and default to 7 if out of range
    return cached result if available
    build URL for FORECAST_HOST/v1/forecast with forecast_days parameter
    fetch and decode JSON via _fetch_json()
    return undef on error or if response has no 'hourly' key
    store result in cache
    return hashref (enforced by Return::Set)

=cut

sub forecast
{
	my $self = shift;
	my $params;

	if(scalar(@_) >= 1 && Scalar::Util::blessed($_[0]) && $_[0]->can('latitude')) {
		# Positional form: (location_obj) or (location_obj, days)
		my $location = $_[0];
		$params = {
			latitude  => $location->latitude(),
			longitude => $location->longitude(),
		};
		$params->{days} = $_[1] if defined($_[1]);
		$params->{tz}   = $location->tz()
			if $location->can('tz') && $ENV{'TIMEZONEDB_KEY'};
	} else {
		$params = Params::Get::get_params(undef, \@_);
	}

	my $latitude  = $params->{latitude};
	my $longitude = $params->{longitude};
	my $location  = $params->{location};
	my $days      = $params->{days} // 7;
	my $tz        = $params->{tz} || DEFAULT_TZ;

	if(!defined($latitude) && defined($location) &&
	   Scalar::Util::blessed($location) && $location->can('latitude')) {
		$latitude  = $location->latitude();
		$longitude = $location->longitude();
	}

	if(!defined($latitude) || !defined($longitude)) {
		my $msg = 'Usage: forecast(latitude => $latitude, longitude => $longitude)';
		$self->{'logger'}->error($msg) if $self->{'logger'};
		Carp::croak($msg);
	}

	$latitude  = _normalise_coord($latitude);
	$longitude = _normalise_coord($longitude);

	my ($lat_clean) = ($latitude  =~ /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/);
	my ($lon_clean) = ($longitude =~ /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/);
	if(!defined($lat_clean) || !defined($lon_clean)) {
		my $msg = __PACKAGE__ . ": Invalid latitude/longitude format ($latitude, $longitude)";
		$self->{'logger'}->error($msg) if $self->{'logger'};
		Carp::croak($msg);
	}
	$latitude  = $lat_clean;
	$longitude = $lon_clean;

	if($days !~ /^\d+$/ || $days < 1 || $days > 16) {
		Carp::carp('days must be between 1 and 16; defaulting to 7');
		$days = 7;
	}

	my $cache_key = "forecast:$latitude:$longitude:$days:$tz";
	if(my $cached = $self->{'cache'}->get($cache_key)) {
		return $cached;
	}

	my $uri = URI->new('https://' . FORECAST_HOST . '/v1/forecast');
	$uri->query_form(
		latitude           => $latitude,
		longitude          => $longitude,
		forecast_days      => $days,
		hourly             => 'temperature_2m,rain,snowfall,weathercode',
		daily              => 'weathercode,temperature_2m_max,temperature_2m_min,rain_sum,snowfall_sum,precipitation_hours,windspeed_10m_max,windgusts_10m_max,sunrise,sunset',
		timezone           => $tz,
		windspeed_unit     => 'mph',
		precipitation_unit => 'inch',
	);
	my $url = $uri->as_string();
	$url =~ s/%2C/,/g;

	my $rc = $self->_fetch_json($url);
	return unless defined($rc) && ref($rc) eq 'HASH';
	return if $rc->{'error'};
	return unless defined($rc->{'hourly'});

	$self->{'cache'}->set($cache_key, $rc);
	return Return::Set::set_return($rc, { type => 'hashref', min => 1 });
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

=head3 PSEUDOCODE

    parse call form (3 variants: hashref, flat list, positional (location) or (location, date))
    extract lat, lon, date, tz; resolve location object if given
    croak if lat or lon is missing
    normalise leading-decimal coordinates via _normalise_coord()
    validate coordinates with /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/
      (atomic groups prevent ReDoS; list-context capture also untaints for perl -T)
    croak if either coordinate does not match
    if date is a strftime object: call strftime('%F')
    carp and return undef if date string is not YYYY-MM-DD
    determine endpoint: archive for historical dates, forecast for today/future
    default date to today if omitted
    return cached result if available
    build URL with daily=sunrise,sunset only (no hourly fields)
    fetch and decode JSON via _fetch_json()
    return undef on error or if daily sunrise/sunset arrays are absent
    extract sunrise[0] and sunset[0]
    store { sunrise, sunset } in cache
    return hashref

=cut

sub sunrise_sunset
{
	my $self = shift;
	my $params;

	if(scalar(@_) >= 1 && Scalar::Util::blessed($_[0]) && $_[0]->can('latitude')) {
		# Positional form: (location_obj) or (location_obj, date)
		my $location = $_[0];
		$params = {
			latitude  => $location->latitude(),
			longitude => $location->longitude(),
		};
		$params->{date} = $_[1] if defined($_[1]);
		$params->{tz}   = $location->tz()
			if $location->can('tz') && $ENV{'TIMEZONEDB_KEY'};
	} else {
		$params = Params::Get::get_params(undef, \@_);
	}

	my $latitude  = $params->{latitude};
	my $longitude = $params->{longitude};
	my $location  = $params->{location};
	my $tz        = $params->{'tz'} || DEFAULT_TZ;

	if(!defined($latitude) && defined($location) &&
	   Scalar::Util::blessed($location) && $location->can('latitude')) {
		$latitude  = $location->latitude();
		$longitude = $location->longitude();
	}

	if(!defined($latitude) || !defined($longitude)) {
		my $msg = 'Usage: sunrise_sunset(latitude => $latitude, longitude => $longitude)';
		$self->{'logger'}->error($msg) if $self->{'logger'};
		Carp::croak($msg);
	}

	$latitude  = _normalise_coord($latitude);
	$longitude = _normalise_coord($longitude);

	my ($lat_clean) = ($latitude  =~ /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/);
	my ($lon_clean) = ($longitude =~ /\A(-?(?>\d+)(?:\.(?>\d+))?)\z/);
	if(!defined($lat_clean) || !defined($lon_clean)) {
		my $msg = __PACKAGE__ . ": Invalid latitude/longitude format ($latitude, $longitude)";
		$self->{'logger'}->error($msg) if $self->{'logger'};
		Carp::croak($msg);
	}
	$latitude  = $lat_clean;
	$longitude = $lon_clean;

	my @t     = localtime(time());
	my $today = sprintf('%04d-%02d-%02d', $t[5] + 1900, $t[4] + 1, $t[3]);
	my $date  = $params->{date};

	if(defined($date) && Scalar::Util::blessed($date) && $date->can('strftime')) {
		$date = $date->strftime('%F');
	}

	if(defined($date) && $date !~ /^\d{4}-\d{2}-\d{2}$/) {
		Carp::carp("'$date' is not a valid date");
		return;
	}

	# No date means use forecast endpoint (more reliable for today than the archive)
	my $use_forecast = !defined($date) || ($date ge $today);
	$date //= $today;

	my $cache_key = "sunrise_sunset:$latitude:$longitude:$date:$tz";
	if(my $cached = $self->{'cache'}->get($cache_key)) {
		return $cached;
	}

	my $endpoint_host = $use_forecast ? FORECAST_HOST  : $self->{host};
	my $endpoint_path = $use_forecast ? '/v1/forecast' : '/v1/archive';

	my $uri = URI->new("https://$endpoint_host$endpoint_path");
	$uri->query_form(
		latitude   => $latitude,
		longitude  => $longitude,
		start_date => $date,
		end_date   => $date,
		daily      => 'sunrise,sunset',
		timezone   => $tz,
	);

	my $rc = $self->_fetch_json($uri->as_string());
	return unless defined($rc) && ref($rc) eq 'HASH' && !$rc->{'error'};

	my $daily = $rc->{'daily'};
	return unless ref($daily) eq 'HASH';

	my $sr = ref($daily->{'sunrise'}) eq 'ARRAY' ? $daily->{'sunrise'}[0] : undef;
	my $ss = ref($daily->{'sunset'})  eq 'ARRAY' ? $daily->{'sunset'}[0]  : undef;
	return unless defined($sr) && defined($ss);

	my $result = { sunrise => $sr, sunset => $ss };
	$self->{'cache'}->set($cache_key, $result);
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
		if(!defined($params->{ua})) {
			$self->{'logger'}->error('ua() requires a defined value') if $self->{'logger'};
			Carp::croak('ua() requires a defined value');
		}
		$self->{ua} = $params->{ua};
	}
	return $self->{ua};
}

# ---------------------------------------------------------------------------
# _normalise_coord -- fix a coordinate that leads with a bare decimal point
#
# Purpose:     Perl and many user inputs write ".5" where "0.5" is required.
#              The regex /^-?\d+(\.\d+)?$/ rejects the bare-dot form, so we
#              normalise before validating.
# Entry:       $coord -- a coordinate string, possibly with a leading "."
# Exit:        normalised string: ".5" -> "0.5", "-.5" -> "-0.5", others unchanged
# Side effects: none
# ---------------------------------------------------------------------------
sub _normalise_coord {
	my ($coord) = @_;
	my $result = $coord;
	# Anchored with \z; atomic group on \d+ prevents O(n) backtracking
	if(my ($frac) = $result =~ /\A-\.((?>\d+))\z/) { $result = "-0.$frac" }
	elsif($result =~ /\A\./)                         { $result = "0$result" }
	return $result;
}

# ---------------------------------------------------------------------------
# _enforce_rate_limit -- sleep until enough time has passed since the last call
#
# Purpose:     Prevent hammering the API when min_interval > 0.
# Entry:       $self -- Weather::Meteo instance with last_request and min_interval
# Exit:        (nothing returned)
# Side effects: may block for up to min_interval seconds via Time::HiRes::sleep
# ---------------------------------------------------------------------------
sub _enforce_rate_limit {
	my ($self) = @_;
	my $elapsed = time() - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}
}

# ---------------------------------------------------------------------------
# _fetch_json -- HTTP GET a URL and decode the response body as JSON
#
# Purpose:     Centralise the HTTP dispatch and JSON parsing steps that are
#              common to all three public data methods, giving one place to
#              maintain error-handling and rate-limiting logic.
# Entry:       $self -- Weather::Meteo instance
#              $url  -- fully-formed request URL string
# Exit:        decoded hashref (or other JSON value) on success; undef on error
# Side effects: enforces rate limit (may sleep); updates last_request timestamp;
#              carps on HTTP errors and JSON parse failures
# ---------------------------------------------------------------------------
sub _fetch_json {
	my ($self, $url) = @_;

	$self->_enforce_rate_limit();

	my $res = $self->{ua}->get($url);
	$self->{last_request} = time();

	unless(defined($res) && ref($res) && $res->can('is_error')) {
		Carp::carp(ref($self) . ': UA->get did not return a valid HTTP response');
		return;
	}

	if($res->is_error()) {
		Carp::carp(ref($self) . ": $url API returned error: " . $res->status_line());
		return;
	}

	my $rc;
	eval { $rc = JSON::MaybeXS->new()->utf8()->decode($res->decoded_content()) };
	if($@) {
		# Sanitise the exception: strip control chars and cap length to prevent
		# log injection or flooding from a malicious API response body
		my $err = "$@";
		$err =~ s/[[:cntrl:]]/ /g;
		$err = substr($err, 0, 200) . '...' if length($err) > 200;
		Carp::carp("Failed to parse JSON response: $err");
		return;
	}

	return $rc;
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

=item * Access control by convention only

Private methods (prefixed with C<_>) are not enforced by a module such as
L<Sub::Private>.
Callers are expected to treat them as internal; white-box test files may
access them directly.

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
it under the same terms as Perl itself.

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
    |   PRE date? !~ /^\d{4}-\d{2}-\d{2}$/                   |
    |     => croak /Invalid date format. Expected YYYY-MM-DD/ |
    |                                                          |
    | PRE year(date?) < 1940                                   |
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
    | PRE date? defined ^ date? !~ /^\d{4}-\d{2}-\d{2}$/     |
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

=head1 LICENSE AND COPYRIGHT

Copyright 2023-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
