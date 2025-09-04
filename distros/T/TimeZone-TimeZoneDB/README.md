# NAME

TimeZone::TimeZoneDB - Interface to [https://timezonedb.com](https://timezonedb.com) for looking up Timezone data

# VERSION

Version 0.04

# SYNOPSIS

    use TimeZone::TimeZoneDB;

    my $tzdb = TimeZone::TimeZoneDB->new(key => 'XXXXXXXX');
    my $tz = $tzdb->get_time_zone({ latitude => 0.1, longitude => 0.2 });

# DESCRIPTION

The `TimeZone::TimeZoneDB` Perl module provides an interface to the [https://timezonedb.com](https://timezonedb.com) API,
enabling users to retrieve timezone data based on geographic coordinates.
It supports configurable HTTP user agents, allowing for proxy settings and request throttling.
The module includes robust error handling, ensuring proper validation of input parameters and secure API interactions.
JSON responses are safely parsed with error handling to prevent crashes.
Designed for flexibility,
it allows users to override default configurations while maintaining a lightweight and efficient structure for querying timezone information.

- Caching

    Identical requests are cached (using [CHI](https://metacpan.org/pod/CHI) or a user-supplied caching object),
    reducing the number of HTTP requests to the API and speeding up repeated queries.

    This module leverages [CHI](https://metacpan.org/pod/CHI) for caching geocoding responses.
    When a geocode request is made,
    a cache key is constructed from the request.
    If a cached response exists,
    it is returned immediately,
    avoiding unnecessary API calls.

- Rate-Limiting

    A minimum interval between successive API calls can be enforced to ensure that the API is not overwhelmed and to comply with any request throttling requirements.

    Rate-limiting is implemented using [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes).
    A minimum interval between API
    calls can be specified via the `min_interval` parameter in the constructor.
    Before making an API call,
    the module checks how much time has elapsed since the
    last request and,
    if necessary,
    sleeps for the remaining time.

# METHODS

## new

    my $tzdb = TimeZone::TimeZoneDB->new();
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->env_proxy(1);
    $tzdb = TimeZone::TimeZoneDB->new(ua => $ua, key => 'XXXXX');

    my $tz = $tzdb->get_time_zone({ latitude => 51.34, longitude => 1.42 })->{'zoneName'};
    print "Ramsgate's time zone is $tz.\n";

Creates a new instance. Acceptable options include:

- `ua`

    An object to use for HTTP requests.
    If not provided, a default user agent is created.

- `host`

    The API host endpoint.
    Defaults to [https://api.timezonedb.com](https://api.timezonedb.com)

- `cache`

    A caching object.
    If not provided,
    an in-memory cache is created with a default expiration of one day.

- `min_interval`

    Minimum number of seconds to wait between API requests.
    Defaults to `0` (no delay).
    Use this option to enforce rate-limiting.

## get\_time\_zone

Returns a hashref with at least one key (the zoneName)

    use Geo::Location::Point;

    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    # Find Ramsgate's time zone
    $tz = $tzdb->get_time_zone($ramsgate)->{'zoneName'}, "\n";

### API SPECIFICATION

#### INPUT

    {
      'latitude' => { type => 'number', min => -90, max => 90 },
      'longitude' => { type => 'number', min => -180, max => 180 },
    }

#### OUTPUT

Argument error: croak
No matches found: undef

    {
      'type' => 'hashref',
      'min' => 1
    }

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $tzdb->ua()->env_proxy(1);

Free accounts are limited to one search a second,
so you can use [LWP::UserAgent::Throttled](https://metacpan.org/pod/LWP%3A%3AUserAgent%3A%3AThrottled) to keep within that limit.

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('timezonedb.com' => 1);
    $tzdb->ua($ua);

# AUTHOR

Nigel Horne, `<njh@bandsman.co.uk>`

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at [https://timezonedb.com](https://timezonedb.com).

# BUGS

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-timezone-timezonedb at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TimeZone-TimeZoneDB](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TimeZone-TimeZoneDB).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

- TimezoneDB API: [https://timezonedb.com/api](https://timezonedb.com/api)
- Testing Dashboard: [https://nigelhorne.github.io/TimeZone-TimeZoneDB/coverage/](https://nigelhorne.github.io/TimeZone-TimeZoneDB/coverage/)

# LICENSE AND COPYRIGHT

Copyright 2023-2025 Nigel Horne.

This program is released under the following licence: GPL2
