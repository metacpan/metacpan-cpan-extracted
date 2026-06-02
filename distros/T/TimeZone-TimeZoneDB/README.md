# NAME

TimeZone::TimeZoneDB - Interface to [https://timezonedb.com](https://timezonedb.com) for looking up Timezone data

# VERSION

Version 0.05

# SYNOPSIS

    use TimeZone::TimeZoneDB;

    my $tzdb = TimeZone::TimeZoneDB->new(key => 'XXXXXXXX');
    my $tz = $tzdb->get_time_zone({ latitude => 0.1, longitude => 0.2 });

# DESCRIPTION

The `TimeZone::TimeZoneDB` Perl module provides an interface to the
[https://timezonedb.com](https://timezonedb.com) API, enabling users to retrieve timezone data
based on geographic coordinates.
It supports configurable HTTP user agents, allowing for proxy settings
and request throttling.
The module includes robust error handling, ensuring proper validation of
input parameters and secure API interactions.
JSON responses are safely parsed with error handling to prevent crashes.
Designed for flexibility, it allows users to override default configurations
while maintaining a lightweight and efficient structure for querying timezone
information.

- Caching

    Identical requests are cached (using [CHI](https://metacpan.org/pod/CHI) or a user-supplied caching object),
    reducing the number of HTTP requests to the API and speeding up repeated queries.

    A cache key is constructed from the normalised coordinates (6 decimal places)
    so that `0.1` and `0.1000000` share the same cache entry.

- Rate-Limiting

    A minimum interval between successive API calls can be enforced to ensure that
    the API is not overwhelmed and to comply with any request throttling requirements.

    Rate-limiting is implemented using [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes).
    A minimum interval between API calls can be specified via the `min_interval`
    parameter in the constructor.
    Before making an API call, the module checks how much time has elapsed since
    the last request and, if necessary, sleeps for the remaining time.

# METHODS

## new

    my $tzdb = TimeZone::TimeZoneDB->new(key => 'XXXXX');

    # With a throttled user-agent that respects free-tier rate limits
    use LWP::UserAgent::Throttled;
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->env_proxy(1);
    $tzdb = TimeZone::TimeZoneDB->new(ua => $ua, key => 'XXXXX');

    # Retrieve the timezone for Ramsgate, UK
    my $tz = $tzdb->get_time_zone({ latitude => 51.34, longitude => 1.42 })->{'zoneName'};
    print "Ramsgate timezone: $tz\n";

Creates and returns a new `TimeZone::TimeZoneDB` instance.
When invoked on an existing object rather than a class name, it returns a
shallow clone of that object with any supplied parameters merged in.
Passing `ua => undef` in a clone call is silently ignored so that the
original user-agent is inherited unchanged.

### ARGUMENTS

- `key` (required)

    API key for timezonedb.com.  Free keys are available at
    [https://timezonedb.com/register](https://timezonedb.com/register).

- `ua` (optional)

    An HTTP user-agent object.  Must respond to `get()`.  Defaults to a plain
    [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) with `gzip,deflate` accepted.

- `host` (optional)

    Override the API hostname.  Defaults to `api.timezonedb.com`.

- `cache` (optional)

    A [CHI](https://metacpan.org/pod/CHI)-compatible caching object.  Defaults to a private in-memory cache
    with a one-day expiry.

- `min_interval` (optional)

    Minimum number of seconds to wait between successive API calls.
    Defaults to `0` (no enforced delay).

### RETURNS

A blessed `TimeZone::TimeZoneDB` reference.
Croaks if `key` is absent.

### SIDE EFFECTS

None.

### NOTES

An optional `logger` key may be passed; if present it must be an object
implementing `warn()` and `error()` (e.g. [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl)).

### API SPECIFICATION

#### INPUT

    {
      'key'          => { type => 'string' },
      'ua'           => { type => 'object', can => 'get',    optional => 1 },
      'host'         => { type => 'string',                  optional => 1 },
      'cache'        => { type => 'object',                  optional => 1 },
      'min_interval' => { type => 'number', min => 0,        optional => 1 },
    }

#### OUTPUT

    { type => 'object' }   # a blessed TimeZone::TimeZoneDB reference

## get\_time\_zone

    my $result = $tzdb->get_time_zone({ latitude => 51.34, longitude => 1.42 });
    print $result->{'zoneName'}, "\n";

    # Also accepts a Geo::Location::Point-compatible object
    use Geo::Location::Point;
    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    my $tz = $tzdb->get_time_zone($ramsgate)->{'zoneName'};

Queries the timezonedb.com API for the IANA timezone name and associated
metadata at the supplied geographic coordinates.
Identical queries are served from cache without making a network request.

### ARGUMENTS

- `latitude` (required)

    Decimal degrees, range `-90` to `+90`.

- `longitude` (required)

    Decimal degrees, range `-180` to `+180`.

    Alternatively, a single [Geo::Location::Point](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APoint)-compatible object (any
    object implementing `latitude()` and `longitude()` methods) may be passed
    instead of a hash or hashref.

### RETURNS

A hashref containing at least `zoneName` on success.
Returns `undef` when the API responds with a non-`OK` status.
Croaks on HTTP errors or invalid arguments.

### SIDE EFFECTS

Updates the internal response cache and the `last_request` timestamp.

### NOTES

The API key is transmitted as a URL query parameter because the
timezonedb.com API does not support an `Authorization` header.
The key is redacted from all error and warning messages to prevent
accidental secret leakage into log aggregators or crash reporters.

### API SPECIFICATION

#### INPUT

    {
      'latitude'  => { type => 'number', min => -90,  max => 90  },
      'longitude' => { type => 'number', min => -180, max => 180 },
    }

#### OUTPUT

    Argument error : croak
    HTTP error     : croak
    Non-OK status  : undef
    Success        : { type => 'hashref', min => 1 }

## ua

    # Getter: retrieve the current user-agent
    my $ua = $tzdb->ua();
    $ua->env_proxy(1);

    # Setter: swap in a throttled agent (returns the new agent for compatibility)
    use LWP::UserAgent::Throttled;
    my $new_ua = LWP::UserAgent::Throttled->new();
    $new_ua->throttle('timezonedb.com' => 1);
    $tzdb->ua($new_ua);

Gets or sets the HTTP user-agent object used for API requests.
The return value is always the current user-agent (after any update),
consistent with the convention used by [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) and related
packages that expose a `ua()` accessor.

### ARGUMENTS

- `ua` (optional)

    Replacement user-agent object.  Must implement a `get($url)` method.
    Omit to use this method as a getter.

### RETURNS

The user-agent object stored on the instance -- the supplied value when
called as a setter, the existing value when called as a getter.
Croaks if a defined but invalid object (no `get()` method) is supplied,
or if `undef` is explicitly passed.

### SIDE EFFECTS

When used as a setter, all subsequent API calls on this object use the new
user-agent.

### NOTES

Free timezonedb.com accounts are rate-limited to one request per second.
Use [LWP::UserAgent::Throttled](https://metacpan.org/pod/LWP%3A%3AUserAgent%3A%3AThrottled) to enforce this transparently.

The accessor always returns the user-agent rather than `$self` so that
callers can do `$tzdb->ua()->env_proxy(1)` in a single expression
without ambiguity about what was returned.

### API SPECIFICATION

#### INPUT

    # Getter (no argument)
    {}

    # Setter
    { 'ua' => { type => 'object', can => 'get' } }

#### OUTPUT

    { type => 'object' }   # the stored user-agent (getter or setter)

# AUTHOR

Nigel Horne, `<njh@nigelhorne.com>`

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at [https://timezonedb.com](https://timezonedb.com).

# BUGS

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-timezone-timezonedb at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TimeZone-TimeZoneDB](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TimeZone-TimeZoneDB).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# SEE ALSO

- TimezoneDB API: [https://timezonedb.com/api](https://timezonedb.com/api)
- [Test Dashboard](https://nigelhorne.github.io/TimeZone-TimeZoneDB/coverage/)

## FORMAL SPECIFICATION

### new

    TimeZoneDB-State ::= [
      key          : STRING ;
      ua           : USERAGENT ;
      host         : STRING ;
      cache        : CACHE ;
      min_interval : ℕ ;
      last_request : ℕ
    ]

    Init
      key?          : STRING
      ua?           : USERAGENT ∪ {⊥}
      host?         : STRING ∪ {⊥}
      cache?        : CACHE ∪ {⊥}
      min_interval? : ℕ ∪ {⊥}
      result!       : TimeZoneDB-State
    ────────────────────────────────────────────────────────
      key? ≠ "" ∧
      result!.key          = key? ∧
      result!.ua           = (if ua? ≠ ⊥ then ua? else DefaultUA) ∧
      result!.host         = (if host? ≠ ⊥ then host? else config.host) ∧
      result!.cache        = (if cache? ≠ ⊥ then cache? else NewCache) ∧
      result!.min_interval = (if min_interval? ≠ ⊥ then min_interval? else 0) ∧
      result!.last_request = 0

### get\_time\_zone

    GetTimeZone
      Δ TimeZoneDB-State   (writes cache and last_request)
      lat? : {n : ℝ | -90 ≤ n ≤ 90}
      lng? : {n : ℝ | -180 ≤ n ≤ 180}
      result! : HASHREF ∪ {⊥}
    ────────────────────────────────────────────────────────
      let k == sprintf(CACHE_KEY_FMT, lat?, lng?)
      ∧ cache.has(k) ⇒
            result! = cache.get(k)
          ∧ last_request' = last_request
          ∧ cache' = cache
      ∧ ¬cache.has(k) ⇒
            let r == ua.get(ApiUrl(lat?, lng?, key))
            ∧ ¬r.ok ⇒ ⊥
            ∧ r.ok ∧ r.json.status = "OK" ⇒
                  result! = r.json
                ∧ cache' = cache ⊕ {k ↦ r.json}
                ∧ last_request' = now
            ∧ r.ok ∧ r.json.status ≠ "OK" ⇒
                  result! = ⊥
                ∧ cache' = cache
                ∧ last_request' = now

## ua

    UA
      Delta TimeZoneDB-State
      ua? : USERAGENT ∪ {⊥}   (⊥ = not supplied)
      ua! : USERAGENT
    ────────────────────────────────────────────────────────
      (ua? = ⊥ ∧ ua' = ua) ∨
      (ua? ≠ ⊥ ∧ defined(ua?) ∧ ua? can 'get'
               ∧ ua' = ua?
               ∧ ∀ x : {key, host, cache, min_interval, last_request} • x' = x)
      ∧ ua! = ua'

# LICENSE AND COPYRIGHT

Copyright 2023-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
