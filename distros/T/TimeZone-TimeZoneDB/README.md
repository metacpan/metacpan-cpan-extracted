# NAME

TimeZone::TimeZoneDB - Interface to [https://timezondb.com](https://timezondb.com) for looking up Timezone data

# VERSION

Version 0.01

# SYNOPSIS

      use TimeZone::TimeZoneDB;

      my $tzdb = TimeZone::TimeZoneDB->new(key => 'XXXXXXXX');
      my $tz = $tzdb->get_time_zone({ latitude => 0.1, longitude => 0.2 });

# DESCRIPTION

TimeZone::TimeZoneDB provides an interface to timezonedb.com
to look up timezones.

# METHODS

## new

    my $tzdb = TimeZone::TimeZoneDB->new();
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->env_proxy(1);
    $tzdb = TimeZone::TimeZoneDB->new(ua => $ua, key => 'XXXXX');

    my $tz = $tzdb->tz({ latitude => 51.34, longitude => 1.42 })->{'zoneName'};
    print "Ramsgate's timezone is $tz.\n";

## get\_time\_zone

    use Geo::Location::Point;

    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    # Find Ramsgate's timezone
    $tz = $tzdb->get_time_zone($ramsgate)->{'zoneName'}, "\n";

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

# SEE ALSO

TimezoneDB API: [https://timezonedb.com/api](https://timezonedb.com/api)

# LICENSE AND COPYRIGHT

Copyright 2023 Nigel Horne.

This program is released under the following licence: GPL2
