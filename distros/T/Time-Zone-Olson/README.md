# NAME

Time::Zone::Olson - Provides an Olson timezone database interface

# VERSION

Version 0.45

# SYNOPSIS

    use Time::Zone::Olson();

    my $time_zone = Time::Zone::Olson->new( timezone => 'Australia/Melbourne' ); # set timezone at creation time
    my $now = $time_zone->time_local($seconds, $minutes, $hours, $day, $month, $year); # convert for Australia/Melbourne time
    foreach my $area ($time_zone->areas()) {
        foreach my $location ($time_zone->locations($area)) {
            $time_zone->timezone("$area/$location");
            print scalar $time_zone->local_time($now); # output time in $area/$location local time
            warn scalar localtime($now) . " log message for sysadmin"; # but log in system local time
        }
    }

# DESCRIPTION

Time::Zone::Olson is intended to provide a simple interface to the Olson database that is available on most UNIX systems.  It provides an interface to list common time zones, such as Australia/Melbourne that are stored in the zone.tab file, and localtime/Time::Local::timelocal replacements to translate times to and from the users time zone, without changing the time zone used by Perl.  This allows logging/etc to be conducted in the system's local time.

Time::Zone::Olson was designed to produce the same result as a 64 bit copy of the [date(1)](http://man.he.net/man1/date) command.

Time::Zone::Olson will attempt to function even without an actual Olson database on Windows platforms by translating information available in the Windows registry.

# SUBROUTINES/METHODS

## new

Time::Zone::Olson->new() will return a new time zone object.  It accepts a hash as a parameter with an optional `timezone` key, which contains an Olson time zone value, such as 'Australia/Melbourne'.  The hash also allows a `directory` key, with the file system location of the Olson time zone database as a value.

Both of these parameters default to `$ENV{TZ}` and `$ENV{TZDIR}` respectively.

## areas

This method will return a list of the areas (such as Asia, Australia, Africa, America, Europe) from the zone.tab file.  The areas will be sorted alphabetically.

## locations

This method accepts a area (such as Asia, Australia, Africa, America, Europe) as a parameter and will return a list of matching locations (such as Melbourne, Perth, Hobart) from the zone.tab file.  The locations will be sorted alphabetically.

## comment

This method accepts the name of time zone such as `"Australia/Melbourne"` as a parameter and will return the matching comment from the zone.tab file.  For example, if `"Australia/Melbourne"` was passed as a parameter, the ["comment"](#comment) function would return `"Victoria"`.  For Windows platforms, it will return the contents of the `Display` registry setting.  For example, for `"Australia/Melbourne"` using English as a language, it would return `"(UTC+10) Canberra, Melbourne, Sydney"`.

## directory

This method can be used to get or set the root directory of the Olson database, usually located at `/usr/share/zoneinfo`.

## timezone

This method can be used to get or set the time zone, which will affect all future calls to ["local\_time"](#local_time) or ["time\_local"](#time_local).  The parameter for this method should be in the Olson format of a time zone, such as `"Australia/Melbourne"`.

## equiv

This method takes a time zone name as a parameter.  It then compares the transition times and offsets for the currently set time zone to the transition times and offsets for the specified time zone and returns true if they match exactly from the current time.  The second optional parameter can specify the start time to use when comparing the two time zones.

## offset

This method can be used to get or set the offset for all ["local\_time"](#local_time) or ["time\_local"](#time_local) calls.  The offset should be specified in minutes from GMT.

## area

This method will return the area component of the current time zone, such as Australia

## location

This method will return the location component of the current time zone, such as Melbourne

## local\_offset

This method takes the same arguments as `localtime` but returns the appropriate offset from GMT in minutes.  This can to used as a `offset` parameter to a subsequent call to Time::Zone::Olson.

## local\_abbr

This method takes the same arguments as `localtime` but returns the appropriate abbreviation for the timezone such as AEST or AEDT.  This is the same result as from a `date +%Z` command.

## local\_time

This method has the same signature as the 64 bit version of the `localtime` function.  That is, it accepts up to a 64 bit signed integer as the sole argument and returns the `(seconds, minutes, hours, day, month, year, wday, yday, isdst)` definition for the time zone for the object.  The time zone used to calculate the local time may be specified as a parameter to the ["new"](#new) method or via the ["timezone"](#timezone) method.

## time\_local

This method has the same signature as the 64 bit version of the `Time::Local::timelocal` function.  That is, it accepts `(seconds, minutes, hours, day, month, year, wday, yday, isdst)` as parameters in a list and returns the correct UNIX time in seconds according to the current time zone for the object.  The time zone used to calculate the local time may be specified as a parameter to the ["new"](#new) method or via the ["timezone"](#timezone) method. 

During a time zone change such as +11 GMT to +10 GMT, there will be two possible UNIX times that can result in the same local time.  In this case, like `Time::Local::timelocal`, this function will return the lower of the two times.

## transition\_times

This method can be used to get the list of transition times for the current time zone.  This method is only intended for testing the results of Time::Zone::Olson.

## determining\_path

This method can be used to determine which file system path was used to determine the current operating system timezone.  If it returns undef, then the current operating system timezone was determined by other means (such as the win32 registry, or comparing the digests of `/etc/localtime` with timezones in ["directory"](#directory)).

## leap\_seconds

This method can be used to get the list of leap seconds for the current time zone.  This method is only intended for testing the results of Time::Zone::Olson.

## reset\_cache

This method can be used to reset the cache.  This method is only intended for testing the results of Time::Zone::Olson.  In actual use, cached values are only used if the `mtime` of the relevant files has not changed.

## tz\_definition

This method will return the TZ environment variable (if any) that describes a timezone after the ["transition\_times"](#transition_times) have been used.  This method is only intended for testing the results of Time::Zone::Olson.

## win32\_mapping 

This method will return a hash containing the mapping between Windows time zones and Olson time zones.  This method is only intended for testing the results of Time::Zone::Olson.

## win32\_registry

This method will return true if the object is using the Windows registry for Olson tz calculations.  Otherwise it will return false.

# DIAGNOSTICS

- `%s is not a TZ file`

    The designated path did not have the `TZif` prefix at the start of the file.  Maybe either the directory or the time zone name is incorrect?

- `Failed to read header from %s:%s`

    The designated file encountered an error reading either the version 1 or version 2 headers

- `Failed to read entire header from %s.  %d bytes were read instead of the expected %d`

    The designated file is shorter than expected

- `%s is not a time zone in the existing Olson database`

    The designated time zone could not be found on the file system.  The time zone is expected to be in the designated directory + the time zone name, for example, /usr/share/zoneinfo/Australia/Melbourne

- `%s does not have a valid format for a TZ time zone`

    The designated time zone name could not be matched by the regular expression for a time zone in Time::Zone::Olson

- `There are two transition times for %s in %s, which cannot be coped with at the moment.  Please file a bug with Time::Zone::Olson`

    The transition times are sorted to handle unsorted (on disk) transition times which has been found on solaris.  Please file a bug.

- `Failed to close %s:%s`

    There has been a file system error while reading or closing the designated path

- `Failed to open %s for reading:%s`

    There has been a file system error while opening the the designated path.  This could be permissions related, or the time zone in question doesn't exist?

- `Failed to stat %s:%s`

    There has been a file system error while doing a [stat](https://metacpan.org/pod/perlfunc#stat) on the designated path.  This could be permissions related, or the time zone in question doesn't exist?

- `Failed to read %s from %s:%s`

    There has been a file system error while reading from the designated path.  The file could be corrupt?

- `Failed to read all the %s from %s.  %d bytes were read instead of the expected %d`

    The designated file is shorter than expected.  The file could be corrupt?

- `The tz definition at the end of %s could not be read in %d bytes`

    The designated file is longer than expected.  Maybe the time zone version is greater than the currently recognized 3?

- `Failed to read tz definition from %s:%`

    There has been a file system error while reading from the designated path.  The file could be corrupt?

- `Failed to parse the tz definition of %s from %s`

    This is probably a bug in Time::Zone::Olson in failing to parse the `TZ` variable at the end of the file.

- `Failed to open %s:%s`

    There has been an error while opening the the designated registry entry.

- `Failed to read from %s:%s`

    There has been an file system error while reading from the registry.

- `Failed to close %s:%s`

    There has been an error while reading or closing the designated registry entry

# CONFIGURATION AND ENVIRONMENT

Time::Zone::Olson requires no configuration files or environment variables.  However, it will use the values of `$ENV{TZ}` and `$ENV{TZDIR}` as defaults for missing parameters.

# DEPENDENCIES

For environments where the unpack 'q' parameter is not supported, the [Math::Int64](https://metacpan.org/pod/Math::Int64) module is required

# INCOMPATIBILITIES

None reported

# BUGS AND LIMITATIONS

On Windows platforms, the Olson TZ database is usually unavailable.  In an attempt to provide a workable alternative, the Windows Registry is interrogated and translated to allow Olson time zones (such as Australia/Melbourne) to be used on Windows nodes.  Therefore, the use of Time::Zone::Olson should be cross-platform compatible, but the actual results may be different, depending on the compatibility of the Windows Registry time zones and the Olson TZ database.

For perl versions less than 5.10, support for TZ environment variable parsing is not complete.  It should cover all existing cases in the Olson time zone database though.

To report a bug, or view the current list of bugs, please visit [https://github.com/david-dick/time-zone-olson/issues](https://github.com/david-dick/time-zone-olson/issues)

# SEE ALSO

- [DateTime::TimeZone](https://metacpan.org/pod/DateTime::TimeZone)
- [DateTime::TimeZone::Tzfile](https://metacpan.org/pod/DateTime::TimeZone::Tzfile)
- [DateTime::TimeZone::Local::Win32](https://metacpan.org/pod/DateTime::TimeZone::Local::Win32)
- [Time::Local](https://metacpan.org/pod/Time::Local)
- [Time::Local::TZ](https://metacpan.org/pod/Time::Local::TZ)

# AUTHOR

David Dick, `<ddick at cpan.org>`

# LICENSE AND COPYRIGHT

Copyright 2021 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
