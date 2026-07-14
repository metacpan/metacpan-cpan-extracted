# NAME

Weather::Meteo - Interface to [https://open-meteo.com](https://open-meteo.com) for historical and forecast weather data

# VERSION

Version 0.15

# SYNOPSIS

The `Weather::Meteo` module provides an interface to the Open-Meteo API for retrieving
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

- Caching

    Identical requests are cached (using [CHI](https://metacpan.org/pod/CHI) or a user-supplied caching object),
    reducing the number of HTTP requests to the API and speeding up repeated queries.

    When a request is made,
    a cache key is constructed from the coordinates, date, and timezone.
    If a cached response exists it is returned immediately,
    avoiding unnecessary API calls.

- Rate-Limiting

    A minimum interval between successive API calls can be enforced to ensure that the
    API is not overwhelmed and to comply with any request throttling requirements.

    Rate-limiting is implemented using [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes).
    A minimum interval between API calls can be specified via the `min_interval` parameter
    in the constructor.
    Before making an API call,
    the module checks how much time has elapsed since the last request and,
    if necessary,
    sleeps for the remaining time.

# METHODS

## new

    my $meteo = Weather::Meteo->new();

    # Custom user agent with proxy support
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $meteo = Weather::Meteo->new(ua => $ua);

    # Clone an existing object and override one slot
    my $clone = $meteo->new(host => 'custom.example.com');

Creates a new `Weather::Meteo` instance.
When called on an existing `Weather::Meteo` object,
clones that object and merges the supplied parameters.

- `cache`

    A caching object.
    If not provided,
    an in-memory cache is created with a default expiration of one hour.

- `host`

    The archive API host endpoint.
    Defaults to `archive-api.open-meteo.com`.

    Must be a plain DNS hostname - letters, digits, hyphens, and dots - with an
    optional port suffix (e.g. `mock.example.com:8080`).
    Values containing `@`, path segments, or other special characters are rejected
    with a `croak` to prevent Server-Side Request Forgery (SSRF) via the
    `WEATHER__METEO__host` environment variable or configuration file.
    Falsy values (`undef`, `""`, `0`) fall back to the default silently.

- `logger`

    An optional logger object.
    Must respond to `error()`.
    When supplied, API errors are reported through this logger in addition to `Carp::carp`.

- `min_interval`

    Minimum number of seconds to wait between API requests.
    Defaults to `0` (no delay).
    Use this option to enforce rate-limiting.

- `ua`

    An object to use for HTTP requests.
    If not provided, a default `LWP::UserAgent` is created.
    Must respond to `get()`.

The class can be configured at runtime using environment variables and configuration files,
for example,
setting `$ENV{'WEATHER__METEO__carp_on_warn'}` causes warnings to use [Carp](https://metacpan.org/pod/Carp).
For more information about runtime configuration,
see [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

### EXAMPLE

    # Minimal -- use all defaults
    my $meteo = Weather::Meteo->new();

    # Custom UA with throttling
    use LWP::UserAgent::Throttled;
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('open-meteo.com' => 1);
    my $meteo = Weather::Meteo->new(ua => $ua, min_interval => 1);

    # Clone the object but change the host for integration testing
    my $test_meteo = $meteo->new(host => 'mock.example.com');

### API SPECIFICATION

#### Input

All parameters are optional.
They may be supplied as a hashref or a flat key/value list.
When `$class` is an existing `Weather::Meteo` object the call clones it,
merging any supplied parameters.

    {
        ua           => { type => 'object', can => 'get',   optional => 1 },
        cache        => { type => 'object',                  optional => 1 },
        host         => { type => 'scalar',                  optional => 1 },
        min_interval => { type => 'scalar',                  optional => 1 },
        logger       => { type => 'object', can => 'error', optional => 1 },
    }

#### Output

    { type => 'object', isa => 'Weather::Meteo' }

### MESSAGES

    Message                                            Type   Trigger
    -------------------------------------------------  -----  -----------------------------------
    'ua' argument must be an object with a get()       croak  clone called with an invalid ua arg
    method
    Invalid host '$host': must be a plain hostname     croak  host contains @, /, or other chars
                                                              that are not safe in a DNS label

## weather

    use Geo::Location::Point;

    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    my $weather  = $meteo->weather($ramsgate, '2022-12-25');

    # Print snowfall at 1AM on Christmas morning in Ramsgate
    my @snowfall = @{$weather->{'hourly'}->{'snowfall'}};
    print 'Snowfall at 1AM: ', $snowfall[1], " cm\n";

    use DateTime;
    my $dt = DateTime->new(year => 2024, month => 2, day => 1);
    $weather = $meteo->weather({ location => $ramsgate, date => $dt });

The date argument can be an ISO-8601 formatted string (`YYYY-MM-DD`),
or any object that supports `strftime`.

Takes an optional `tz` argument containing the time zone.
If not given, the module tries to derive it from the location object;
set `TIMEZONEDB_KEY` to your API key from [https://timezonedb.com](https://timezonedb.com) to enable that.
If all else fails, the module falls back to `Europe/London`.

Dates before 1940 return `undef` silently.
Invalid date strings cause a `carp` and return `undef`.
Missing required arguments or non-numeric coordinates cause a `croak`.

On success returns a hashref with at minimum an `hourly` key.
The `daily` key includes `sunrise` and `sunset` as ISO-8601 datetime strings
(e.g. `2022-12-25T08:09`), as well as temperature, precipitation, and wind fields.
Returns `undef` if the API returns an error, if the JSON cannot be
parsed, or if the response contains no `hourly` key.

### EXAMPLE

    my $meteo   = Weather::Meteo->new();
    my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });

    if(defined($weather)) {
        my $max_temp = $weather->{'daily'}->{'temperature_2m_max'}[0];
        my $sunrise  = $weather->{'daily'}->{'sunrise'}[0];
        my @temps    = @{$weather->{'hourly'}->{'temperature_2m'}};
        print "Max temp: ${max_temp}C  Sunrise: $sunrise\n";
        print "Temp at noon: $temps[12]C\n";
    }

### API SPECIFICATION

#### Input

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

#### Output

    { type => 'hashref', min => 1 }   # success -- contains 'hourly' key
    undef                              # pre-1940 date, bad input, or API error

### MESSAGES

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

### PSEUDOCODE

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

## forecast

    my $meteo    = Weather::Meteo->new();
    my $forecast = $meteo->forecast({ latitude => 51.34, longitude => 1.42 });
    my @temps    = @{$forecast->{'hourly'}->{'temperature_2m'}};

    # Request 3 days of forecast
    $forecast = $meteo->forecast({ latitude => 51.34, longitude => 1.42, days => 3 });

    use Geo::Location::Point;
    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    $forecast = $meteo->forecast($ramsgate);
    $forecast = $meteo->forecast($ramsgate, 5);

Fetches weather forecast data from [https://api.open-meteo.com](https://api.open-meteo.com).
Returns up to 16 days of hourly and daily data.
The `daily` key of the response includes `sunrise` and `sunset` ISO-8601 datetime strings.

Takes an optional `days` argument (integer 1-16, default 7).
Takes an optional `tz` argument for the time zone; defaults to `Europe/London`.

On success returns a hashref containing at minimum the key `hourly`.
Returns `undef` if the API returns an error, if the JSON cannot be parsed,
or if the response contains no `hourly` key.

### EXAMPLE

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

### API SPECIFICATION

#### Input

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

#### Output

    { type => 'hashref', min => 1 }   # success -- contains 'hourly' key
    undef                              # bad input or API error

### MESSAGES

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

### PSEUDOCODE

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

## sunrise\_sunset

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

Returns a hashref with `sunrise` and `sunset` ISO-8601 datetime strings
(e.g. `2022-12-25T08:09`) for the given location and date.

If no date is supplied, today is used and the forecast endpoint is queried.
For historical dates (strictly before today) the archive endpoint is used.
For today and future dates the forecast endpoint ([https://api.open-meteo.com](https://api.open-meteo.com)) is used.

Takes an optional `tz` argument for the time zone; defaults to `Europe/London`.

Returns `undef` if the API returns an error or if the response does not contain
sunrise/sunset data.

### EXAMPLE

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

### API SPECIFICATION

#### Input

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

#### Output

    { type => 'hashref' }   # { sunrise => STRING, sunset => STRING }
    undef                    # bad input or API error

### MESSAGES

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

### PSEUDOCODE

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

## ua

Accessor method to get and set the `UserAgent` object used internally.
You can call `env_proxy` for example, to get proxy information from
environment variables:

    $meteo->ua()->env_proxy(1);

You can also replace the user agent entirely:

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('open-meteo.com' => 1);
    $meteo->ua($ua);

### EXAMPLE

    my $meteo = Weather::Meteo->new();

    # Getter: inspect the current UA
    my $ua = $meteo->ua();
    $ua->env_proxy(1);

    # Setter: replace with a throttled UA
    use LWP::UserAgent::Throttled;
    $meteo->ua(LWP::UserAgent::Throttled->new());

### API SPECIFICATION

#### Input

When called with no arguments acts as a getter; the input schema is empty.
When called with an argument the argument must be an object that responds to `get`:

    { ua => { type => 'object', can => 'get' } }

#### Output

    { type => 'object', can => 'get' }

### MESSAGES

    Message                                              Type   Trigger
    ---------------------------------------------------  -----  ----------------------------------
    ua() requires a defined value                        croak  ua(undef) called
    must be an object that understands the get method    croak  ua arg lacks get() method

# LIMITATIONS

- Archive data lag

    The Open-Meteo archive endpoint has a lag of approximately five days before
    recent historical data becomes available.
    For dates within the past five days,
    `weather()` may return `undef` even when no error occurs.
    Use `forecast()` or `sunrise_sunset()` (without a date) to obtain data for
    today or recent days.

- Coordinate range

    The module normalises coordinates with a bare leading decimal point (e.g.
    `".5"` to `"0.5"`) but does not validate that latitude is within `-90..90`
    or longitude within `-180..180`.
    Out-of-range values are passed to the API, which may return an error.

- No sub-hourly resolution

    The hourly data arrays always contain exactly 24 entries per day (one per hour).
    Sub-hourly resolution is not supported by this interface.

- Per-process rate limiting

    The `min_interval` rate limiter tracks the last request timestamp within a
    single process instance.
    Multiple concurrent processes or threads are not coordinated and may collectively
    exceed the desired request rate.

- Timezone resolution requires an API key

    Automatic per-location timezone resolution requires setting the
    `TIMEZONEDB_KEY` environment variable to a valid key from
    [https://timezonedb.com](https://timezonedb.com).
    Without it the module defaults to `Europe/London` for all locations.

- No list-context support

    `weather()` and `forecast()` enforce scalar/hashref context via
    [Return::Set](https://metacpan.org/pod/Return%3A%3ASet).
    List context is not currently supported.

- Access control by convention only

    Private methods (prefixed with `_`) are not enforced by a module such as
    [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate).
    Callers are expected to treat them as internal; white-box test files may
    access them directly.

- Host parameter restricted to plain DNS hostnames

    The `host` constructor parameter (and the `WEATHER__METEO__host` environment
    variable) must match `/\A[A-Za-z0-9][A-Za-z0-9.\-]*(:\d{1,5})?\z/`.
    IP addresses in CIDR notation, URLs with path components, `@`-style
    user-info, and other special characters are rejected with a `croak` to
    prevent Server-Side Request Forgery.
    If you need to test against a local service on a non-standard port, use a
    plain `hostname:port` string (e.g. `localhost:8080`).

- Coordinate values limited to decimal numbers

    Latitude and longitude must match `/\A-?(?`\\d+)(?:\\.(?>\\d+))?\\z/> after
    leading-decimal normalisation.
    Exponential notation (`1.5e2`), hex (`0x1F`), and strings with embedded
    whitespace are rejected.
    Pass a pre-formatted decimal string rather than a Perl numeric expression if
    your caller might produce non-decimal representations.

# AUTHOR

Nigel Horne, `<njh@nigelhorne.com>`

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at [https://open-meteo.com](https://open-meteo.com).

# BUGS

Please report any bugs or feature requests to `bug-weather-meteo at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-Meteo](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-Meteo).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

- Open Meteo API: [https://open-meteo.com/en/docs#api\_form](https://open-meteo.com/en/docs#api_form)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Weather-Meteo/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Weather::Meteo

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Weather-Meteo](https://metacpan.org/release/Weather-Meteo)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Weather-Meteo](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Weather-Meteo)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Weather-Meteo](http://cpants.cpanauthors.org/dist/Weather-Meteo)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Weather-Meteo](http://matrix.cpantesters.org/?dist=Weather-Meteo)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Weather-Meteo](http://deps.cpantesters.org/?module=Weather-Meteo)

# FORMAL SPECIFICATION

## new

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

## weather

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

## forecast

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

## sunrise\_sunset

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

## ua

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

# LICENSE AND COPYRIGHT

Copyright 2023-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
