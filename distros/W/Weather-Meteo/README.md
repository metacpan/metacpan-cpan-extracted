## Name

Weather::Meteo - Interface to [https://open-meteo.com](https://open-meteo.com) for historical and forecast weather data

## Version

Version 0.16

## Synopsis

The `Weather::Meteo` module provides an interface to the Open-Meteo API for retrieving
historical weather data from 1940 and weather forecasts up to 16 days ahead.
It allows users to fetch weather information by specifying latitude, longitude, and a date.
The module supports object-oriented usage and allows customisation of the HTTP user agent.

```perl
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
```

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

## Methods

### New

```perl
my $meteo = Weather::Meteo->new();

# Custom user agent with proxy support
my $ua = LWP::UserAgent->new();
$ua->env_proxy(1);
$meteo = Weather::Meteo->new(ua => $ua);

# Clone an existing object and override one slot
my $clone = $meteo->new(host => 'custom.example.com');
```

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

- `max_retries`

    Maximum number of times a request is retried after a transient failure:
    HTTP 429 (Too Many Requests), 502, 503 or 504.
    Defaults to `3`.
    Set to `0` to disable retrying.
    Other errors, including HTTP 500 and 404, are never retried.

- `messages`

    A hashref of message keys to replacement text, for translating or rewording
    the module's warnings and errors.
    See ["i18n"](#i18n) for the keys, the placeholder syntax and plural support.
    Defaults to the built-in English messages.

- `min_interval`

    Minimum number of seconds to wait between API requests.
    May be fractional, for example `0.5`.
    Defaults to `0` (no delay).
    Use this option to enforce rate-limiting.

- `retry_delay`

    Base delay in seconds before the first retry.
    The delay doubles on each subsequent retry (`retry_delay`, `2 * retry_delay`, ...).
    A numeric `Retry-After` header from the server takes precedence.
    Waits are capped at 60 seconds.
    Defaults to `1`.

- `ua`

    An object to use for HTTP requests.
    If not provided, a default `LWP::UserAgent` is created.
    Must respond to `get()`.

The class can be configured at runtime using environment variables and configuration files,
for example,
setting `$ENV{'WEATHER__METEO__carp_on_warn'}` causes warnings to use [Carp](https://metacpan.org/pod/Carp).
For more information about runtime configuration,
see [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

#### Example

```perl
# Minimal -- use all defaults
my $meteo = Weather::Meteo->new();

# Custom UA with throttling
use LWP::UserAgent::Throttled;
my $ua = LWP::UserAgent::Throttled->new();
$ua->throttle('open-meteo.com' => 1);
my $meteo = Weather::Meteo->new(ua => $ua, min_interval => 1);

# Clone the object but change the host for integration testing
my $test_meteo = $meteo->new(host => 'mock.example.com');
```

#### Api Specification

##### Input

All parameters are optional.
They may be supplied as a hashref or a flat key/value list.
When `$class` is an existing `Weather::Meteo` object the call clones it,
merging any supplied parameters.

```perl
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
```

##### Output

```perl
{ type => 'object', isa => 'Weather::Meteo' }
```

#### Messages

```
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
```

### Weather

```perl
use Geo::Location::Point;

my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
my $weather  = $meteo->weather($ramsgate, '2022-12-25');

# Print snowfall at 1AM on Christmas morning in Ramsgate
my @snowfall = @{$weather->{'hourly'}->{'snowfall'}};
print 'Snowfall at 1AM: ', $snowfall[1], " cm\n";

use DateTime;
my $dt = DateTime->new(year => 2024, month => 2, day => 1);
$weather = $meteo->weather({ location => $ramsgate, date => $dt });
```

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

#### Example

```perl
my $meteo   = Weather::Meteo->new();
my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });

if(defined($weather)) {
    my $max_temp = $weather->{'daily'}->{'temperature_2m_max'}[0];
    my $sunrise  = $weather->{'daily'}->{'sunrise'}[0];
    my @temps    = @{$weather->{'hourly'}->{'temperature_2m'}};
    print "Max temp: ${max_temp}C  Sunrise: $sunrise\n";
    print "Temp at noon: $temps[12]C\n";
}
```

#### Api Specification

##### Input

Three call forms are accepted.

```perl
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
```

##### Output

```perl
{ type => 'hashref', min => 1 }   # success -- contains 'hourly' key
undef                              # pre-1940 date, bad input, or API error
```

#### Messages

```perl
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
```

#### Pseudocode

```perl
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
```

### Forecast

```perl
my $meteo    = Weather::Meteo->new();
my $forecast = $meteo->forecast({ latitude => 51.34, longitude => 1.42 });
my @temps    = @{$forecast->{'hourly'}->{'temperature_2m'}};

# Request 3 days of forecast
$forecast = $meteo->forecast({ latitude => 51.34, longitude => 1.42, days => 3 });

use Geo::Location::Point;
my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
$forecast = $meteo->forecast($ramsgate);
$forecast = $meteo->forecast($ramsgate, 5);
```

Fetches weather forecast data from [https://api.open-meteo.com](https://api.open-meteo.com).
Returns up to 16 days of hourly and daily data.
The `daily` key of the response includes `sunrise` and `sunset` ISO-8601 datetime strings.

Takes an optional `days` argument (integer 1-16, default 7).
Anything that is not a whole number from 1 to 16, such as `0`, `17`, `1.5` or `abc`,
is replaced by 7 with a warning.
Takes an optional `tz` argument for the time zone; defaults to `Europe/London`.

On success returns a hashref containing at minimum the key `hourly`.
Returns `undef` if the API returns an error, if the JSON cannot be parsed,
or if the response contains no `hourly` key.

#### Example

```perl
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
```

#### Api Specification

##### Input

Three call forms are accepted.

```perl
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
```

##### Output

```perl
{ type => 'hashref', min => 1 }   # success -- contains 'hourly' key
undef                              # bad input or API error
```

#### Messages

```perl
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
```

#### Pseudocode

```
params = _location_params(args)         # hashref, flat list or (location, days)
(lat, lon) = _coordinates(params)       # croak if missing or not decimal numbers
days = params.days // 7
if days is not an integer in 1..16: carp 'days_range'; days = 7
url = _build_url(forecast host, '/v1/forecast', forecast_days, hourly+daily, units)
return _cached_report(key, url)         # as for weather()
```

### Sunrise\_Sunset

```perl
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
```

Returns a hashref with `sunrise` and `sunset` ISO-8601 datetime strings
(e.g. `2022-12-25T08:09`) for the given location and date.

If no date is supplied, today is used and the forecast endpoint is queried.
For historical dates (strictly before today) the archive endpoint is used.
For today and future dates the forecast endpoint ([https://api.open-meteo.com](https://api.open-meteo.com)) is used.

Takes an optional `tz` argument for the time zone; defaults to `Europe/London`.

Returns `undef` if the API returns an error or if the response does not contain
sunrise/sunset data.

#### Example

```perl
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
```

#### Api Specification

##### Input

Three call forms are accepted.

```perl
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
```

##### Output

```perl
{ type => 'hashref' }   # { sunrise => STRING, sunset => STRING }
undef                    # bad input or API error
```

#### Messages

```perl
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
```

#### Pseudocode

```perl
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
```

### Ua

Accessor method to get and set the `UserAgent` object used internally.
You can call `env_proxy` for example, to get proxy information from
environment variables:

```
$meteo->ua()->env_proxy(1);
```

You can also replace the user agent entirely:

```perl
use LWP::UserAgent::Throttled;

my $ua = LWP::UserAgent::Throttled->new();
$ua->throttle('open-meteo.com' => 1);
$meteo->ua($ua);
```

#### Example

```perl
my $meteo = Weather::Meteo->new();

# Getter: inspect the current UA
my $ua = $meteo->ua();
$ua->env_proxy(1);

# Setter: replace with a throttled UA
use LWP::UserAgent::Throttled;
$meteo->ua(LWP::UserAgent::Throttled->new());
```

#### Api Specification

##### Input

When called with no arguments acts as a getter; the input schema is empty.
When called with an argument the argument must be an object that responds to `get`:

```perl
{ ua => { type => 'object', can => 'get' } }
```

##### Output

```perl
{ type => 'object', can => 'get' }
```

#### Messages

```
Message                                              Type   Trigger
---------------------------------------------------  -----  ----------------------------------
ua() requires a defined value                        croak  ua(undef) called
must be an object that understands the get method    croak  ua arg lacks get() method
```

### i18n

```perl
my $text = $meteo->i18n('days_range', { min => 1, max => 16, default => 7 });
```

Returns the text of a diagnostic message, with its placeholders filled in.
Every warning and error raised by this module is produced through this method,
so each one can be translated or reworded without touching the code.

Messages are looked up first in the `messages` hashref given to ["new"](#new),
then in the built-in English table.
Placeholders are written `{name}` and are replaced from the arguments hashref.
A placeholder with no matching argument is left as it is, so a missing value is
visible in the output instead of silently vanishing.

A message may be a hashref of variants instead of a string.
The variant is chosen by the `count` argument (`one` if it is 1, otherwise
`other`) and, if a `gender` argument is also given, the variant named
`` one_`gender` `` or `` other_`gender` `` is preferred when it exists.
Only the English rule for singular and plural is built in; translators for
languages with more plural forms should put the form they need under `other`
or add their own keys and select them with `count`.

If the arguments hashref has a `sprintf` arrayref, the message is first passed
through `sprintf` with those values, which allows `%s` style translations.

Can be called as a class method.
Confesses (with a stack trace) if the key is unknown, because that is a
programming error and not something a caller can recover from.

#### Example

```perl
# Built-in English
print $meteo->i18n('invalid_host', { value => 'bad host' }), "\n";

# German overrides, with a plural
my $de = Weather::Meteo->new(messages => {
    days_range => 'Tage muessen zwischen {min} und {max} liegen; verwende {default}',
    days_left  => { one => 'noch {count} Tag', other => 'noch {count} Tage' },
});
print $de->i18n('days_left', { count => 3 }), "\n";    # noch 3 Tage
```

#### Api Specification

##### Input

```perl
{
    key  => { type => 'string' },
    args => { type => 'hashref', optional => 1 },
}
```

##### Output

```perl
{ type => 'string', min => 1 }
```

#### Messages

```
Message                                              Type     Trigger
---------------------------------------------------  -------  ----------------------------------
Weather::Meteo: no message defined for key '$key'    confess  key is in neither table
Weather::Meteo: no '$category' variant in message    confess  variant hashref lacks one/other
```

## Limitations

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

- Access control is enforced, but only by convention for subclasses

    Helper functions with no need of an object (coordinate and URL handling, retry
    arithmetic) are [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) and cannot be called, overridden or mocked from
    outside this file.
    Helper methods that need the object are [Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected): callable from this
    class and its subclasses but not from unrelated code.
    White-box tests therefore have to go through the public methods or subclass
    `Weather::Meteo`.

    Both modules switch their checks off when `$ENV{HARNESS_ACTIVE}` is set,
    which `prove` and `make test` do, so under a test harness the helpers can be
    called from anywhere.
    Set `$Sub::Private::config{harness_bypass}` and
    `$Sub::Protected::config{harness_bypass}` to `0` to test the enforcement
    itself, as `t/i18n.t` does.
    Also note that [Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected) registers the `:Protected` attribute in
    `UNIVERSAL`, so it is available to every package in the process once this
    module is loaded.
    The cost of this strictness is that a subclass can reuse the protected methods
    but not the private functions, so it cannot change, for example, how URLs are built.

- Errors are reported as `undef` plus a warning

    Every failure of `weather()`, `forecast()` and `sunrise_sunset()` that is not
    a usage error comes back as `undef` with a `carp`.
    A caller therefore cannot tell a rate limit from an outage from an unknown
    place without parsing the warning text.
    This is the documented contract, kept for compatibility, but an exception
    class (or at least a `last_error()` accessor) would be a better design.

- Retries block the caller

    Retrying a transient failure sleeps in the calling process, for up to
    `max_retries` times the (doubling, capped) delay: about 7 seconds with the
    defaults.
    Set `max_retries` to `0` for a non-blocking client, or do the retrying
    yourself.

- Messages are translatable, but the plural rules are not

    ["i18n"](#i18n) understands `one` and `other` only, which is right for English,
    German and French but not for languages with several plural forms.
    It also does not translate strings that come from outside the module, such as
    the text of an HTTP status line or an exception from the JSON decoder.

- Dates are checked by shape, not by calendar

    `2022-02-31` and `2022-13-45` have the shape `YYYY-MM-DD` and are passed to
    the API, which rejects them.
    The module does not check them itself because no calendar module is a
    dependency.

- "Today" is the host's date, not the location's

    When `sunrise_sunset()` is called without a date, or with today's date, "today"
    is taken from the local clock of the machine running the code, not from the
    `tz` requested.
    Near midnight and for distant time zones that can be a day out.

- Cache keys use the text of the coordinates

    `51.34` and `51.340` are cached separately, and so are `tz` spellings that
    the API treats as the same zone.
    The results are correct; only the hit rate suffers.

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

## Author

Nigel Horne, `<njh@nigelhorne.com>`

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License, version 2.
See ["LICENSE AND COPYRIGHT"](#license-and-copyright) below.

Lots of thanks to the folks at [https://open-meteo.com](https://open-meteo.com).

## Bugs

Please report any bugs or feature requests to `bug-weather-meteo at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-Meteo](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-Meteo).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

## See Also

- Open Meteo API: [https://open-meteo.com/en/docs#api\_form](https://open-meteo.com/en/docs#api_form)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Weather-Meteo/coverage/)

## Support

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

```
perldoc Weather::Meteo
```

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

## Formal Specification

### New

```perl
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
```

### Weather

```perl
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
```

### Forecast

```perl
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
```

### Sunrise\_Sunset

```perl
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
```

### Ua

```perl
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
```

### i18n

```perl
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
```

## License and Copyright

Copyright 2023-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
