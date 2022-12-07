# NAME

TimeZone::Solar - local solar timezone lookup and utilities including DateTime compatibility

# SYNOPSIS

Using TimeZone::Solar alone, with longitude only:

    use TimeZone::Solar;
    use feature qw(say);

    # example without latitude - assumes between 80N and 80S latitude
    my $solar_tz = TimeZone::Solar->new( longitude => -121.929 );
    say join " ", ( $solar_tz->name, $solar_tz->short_name, $solar_tz->offset,
      $solar_tz->offset_min );

This outputs "Solar/West08 West08 -08:00 -480" using an hour-based time zone.

Using TimeZone::Solar alone, with longitude and latitude:

    use TimeZone::Solar;
    use feature qw(say);

    # example with latitude (location: SJC airport, San Jose, California)
    my $solar_tz_lat = TimeZone::Solar->new( latitude => 37.363,
      longitude => -121.929, use_lon_tz => 1 );
    say $solar_tz_lat;

This outputs "Solar/Lon122W -08:08" using a longitude-based time zone.

Using TimeZone::Solar with DateTime:

    use DateTime;
    use TimeZone::Solar;
    use feature qw(say);

    # noon local solar time at 122W longitude, i.e. San Jose CA or Seattle WA
    my $dt = DateTime->new( year => 2022, month => 6, hour => 1,
      time_zone => "Solar/West08" );

    # convert to US Pacific Time (works for Standard or Daylight conversion)
    $dt->set_time_zone( "US/Pacific" );
    say $dt;

This code prints "2022-06-01T13:00:00", which means noon was converted to
1PM, because Solar/West08 is equivalent to US Pacific Standard Time,
centered on 120W longitude. And Standard Time is 1 hour off from Daylight
Time, which changed noon Solar Time to 1PM Daylight Time.

# DESCRIPTION

_TimeZone::Solar_ provides lookup and conversion utilities for Solar time zones, which are based on
the longitude of any location on Earth. See the next subsection below for more information.

Through compatibility with [DateTime::TimeZone](https://metacpan.org/pod/DateTime%3A%3ATimeZone), _TimeZone::Solar_ allows the [DateTime](https://metacpan.org/pod/DateTime) module to
convert either direction between standard (Olson Database) timezones and Solar time zones.

## Overview of Solar time zones

Solar time zones are based on the longitude of a location. Each time zone is defined around having
local solar noon, on average, the same as noon on the clock.

Solar time zones are always in Standard Time. There are no Daylight Time changes, by definition. The main point
is to have a way to opt out of Daylight Saving Time by using solar time.

The Solar time zones build upon existing standards.

- Lines of longitude are a well-established standard.
- Ships at sea use "nautical time" based on time zones 15 degrees of longitude wide.
- Time zones (without daylight saving offsets) are based on average solar noon at the Prime Meridian. Standard Time in
each time zone lines up with average solar noon on the meridian at the center of each time zone, at 15-degree of
longitud e increments.

15 degrees of longitude appears more than once above. That isn't a coincidence. It's derived from 360 degrees
of rotation in a day, divided by 24 hours in a day. The result is 15 degrees of longitude representing 1 hour
in Earth's rotation. That makes each time zone one hour wide. So Solar time zones use that too.

The Solar Time Zones proposal is intended as a potential de-facto standard which people can use in their
local areas, providing for routine computational time conversion to and from local standard or daylight time.
In order for the proposal to become a de-facto standard, made in force by the number of people using it,
it starts with technical early adopters choosing to use it. At some point it would actually become an
official alternative via publication of an Internet RFC and adding the new time zones into the
Internet Assigned Numbers Authority (IANA) Time Zone Database files. The Time Zone Database feeds
the time zone conversions used by computers including servers, desktops, phones and embedded devices.

There are normal variations of a matter of minutes between local solar noon and clock noon, depending on
the latitude and time of year. That variation is always the same number of minutes as local solar noon
differs from noon UTC at the same latitude on the Prime Meridian (0° longitude), due to seasonal effects
of the tilt in Earth's axis relative to our orbit around the Sun.

The Solaer time zones also have another set of overlay time zones the width of 1 degree of longitude, which puts
them in 4-minute intervals of time. These are a hyper-local niche for potential use by outdoor events or activities
which must be scheduled around daylight. They can also be used by anyone who wants the middle of the scheduling day
to coincide closely with local solar noon.

## Definition of Solar time zones

The Solar time zones definition includes the following rules.

- There are 24 hour-based Solar Time Zones, named West12, West11, West10, West09 through East12. East00 is equivalent to UTC. West00 is an alias for East00.
    - Hour-based time zones are spaced in one-hour time increments, or 15 degrees of longitude.
    - Each hour-based time zone is centered on a meridian at a multiple of 15 degrees. In positive and negative integers, these are 0, 15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165 and 180.
    - Each hour-based time zone spans the area ±7.5 degrees of longitude either side of its meridian.
- There are 360 longitude-based Solar Time Zones, named Lon180W for 180 degrees West through Lon180E for 180 degrees East. Lon000E is equivalent to UTC. Lon000W is an alias for Lon000E.
    - Longitude-based time zones are spaced in 4-minute time increments, or 1 degree of longitude.
    - Each longitude-based time zone is centered on the meridian of an integer degree of longitude.
    - Each longitude-based time zone spans the area ±0.5 degrees of longitude either side of its meridian.
- In both hourly and longitude-based time zones, there is a limit to their usefulness at the poles. Beyond 80 degrees north or south, the definition uses UTC (East00 or Lon000E). This boundary is the only reason to include latitude in the computation of the time zone.
- When converting coordinates to a time zone, each time zone includes its boundary meridian at the lower end of its absolute value, which is in the direction toward 0 (UTC). The exception is at exactly ±180.0 degrees, which would be excluded from both sides by this rule. That case is arbitrarily set as +180 just to pick one.
- The category "Solar" is used for the longer names for these time zones. The names listed above are the short names. The full long name of each time zone is prefixed with "Solar/" such as "Solar/East00" or "Solar/Lon000E".

# FUNCTIONS AND METHODS

## Class methods

- $obj = TimeZone::Solar->new( longitude => $float, use\_lon\_tz => $bool, \[latitude => $float\] )

    Create a new instance of the time zone for the given longitude as a floating point number. The "use\_lon\_tz" parameter
    is a boolean flag which if true selects longitude-based time zones, at a width of 1 degree of longitude. If false or
    omitted, it selects hour-based time zones, at a width of 15 degrees of longitude.

    If a latitude parameter is provided, it only makes a difference if the latitude is within 10° of the poles,
    at or beyond 80° North or South latitude. In the polar regions, it uses the equivalent of UTC, which is Solar/East00
    for hour-based time zones or Solar/Lon000E for longitude-based time zones.

    _TimeZone::Solar_ uses a singleton pattern. So if a given solar time zone's class within the
    _DateTime::TimeZone::Solar::\*_ hierarchy already has an instance, that one will be returned.
    A new instance is only returned the first time.

- $obj = DateTime::TimeZone::Solar::_timezone_->new()

    This is the same class method as TimeZone::Solar->new() except that if called with a class in the
    _DateTime::TimeZone::Solar::\*_ hierarchy, it obtains the time zone parameters from the class name.
    If an instance exists for that solar time zone class, then that instance is returned.
    If not, a new one is instantiated and returned.

- $obj = DateTime::TimeZone::Solar::_timezone_->instance()

    For compatibility with _DateTime::TimeZone_, the instance() method returns the class' instance if it exists.
    Otherwise it is created using the class name to fill in its parameters via the new() method.

- TimeZone::Solar->version()

    Return the version number of TimeZone::Solar, or for any subclass which inherits the method.

    When running code within a source-code development workspace, it returns "00-dev" to avoid warnings
    about undefined values.
    Release version numbers are assigned and added by the build system upon release,
    and are not available when running directly from a source code repository.

## instance methods

- $obj->longitude()

    returns the longitude which was used to instantiate the time zone object.
    This is mainly intended for testing. Once instantiated the time zone object serves all areas in its boundary.

- $obj->latitude()

    returns the latitude which was used to instantiate the time zone object, or undef if none was provided.
    This is mainly intended for testing. Once instantiated the time zone object serves all areas in its boundary.

- $obj->name()

    returns a string with the long name, including the "Solar/" prefix, of the time zone.

- $obj->long\_name()

    returns a string with the long name, including the "Solar/" prefix, of the time zone.
    This is equivalent to $obj->name().

- $obj->short\_name()

    returns a string with the short name, excluding the "Solar/" prefix, of the time zone.

- $obj->offset()

    returns a string with the time zone's offset from UTC in hour-minute format like +01:01 or -01:01 .
    If seconds matter, it will include them in the format +01:01:01 or -01:01:01 .

- $obj->offset\_str()

    returns a string with the time zone's offset from UTC in hour-minute format, equivalent to $obj->offset().

- $obj->offset\_min()

    returns an integer with the number of minutes of the time zone's offest from UTC.

- $obj->offset\_sec()

    returns an integer with the number of seconds of the time zone's offest from UTC.

## DateTime::TimeZone compatibility methods

- spans()

    always returns an empty list because there are never any Daylight Time transitions in solar time zones.

- has\_dst\_changes()

    always returns 0 (false) because there are never any Daylight Time transitions in solar time zones.

- is\_floating()

    always returns 0 (false) because the solar time zones are not floating time zones.

- is\_olson()

    always returns 0 (false) because the solar time zones are not in the Olson time zone database.
    (Maybe some day.)

- category()

    always returns "Solar" for the time zone category.

- is\_utc()

    Returns 1 (true) if the time zone is equivalent to UTC, meaning at 0 offset from UTC. This is only the case for
    Solar/East00, Solar/West00 (which is an alias for Solar/East00), Solar/Lon000E and Solar/Lon000W (which is an alias
    for Solar/Lon000E). Otherwise it returns 0 because the time zone is not UTC.

- is\_dst\_for\_datetime()

    always returns 0 (false) because Daylight Saving Time never occurs in Solar time zones.

- offset\_for\_datetime()

    returns the time zone's offset from UTC in seconds. This is equivalent to $obj->offset\_sec().

- offset\_for\_local\_datetime()

    returns the time zone's offset from UTC in seconds. This is equivalent to $obj->offset\_sec().

- short\_name\_for\_datetime()

    returns the time zone's short name, without "Solar/". This is equivalent to $obj->short\_name().

_TimeZone::Solar_ also overloads the eq (string equality) and "" (convert to string) operators for
compatibility with _DateTime::TimeZone_.

# LICENSE

_TimeZone::Solar_ is Open Source software licensed under the GNU General Public License Version 3.
See [https://www.gnu.org/licenses/gpl-3.0-standalone.html](https://www.gnu.org/licenses/gpl-3.0-standalone.html).

# SEE ALSO

LongitudeTZ on Github: https://github.com/ikluft/LongitudeTZ

# BUGS AND LIMITATIONS

Please report bugs via GitHub at [https://github.com/ikluft/LongitudeTZ/issues](https://github.com/ikluft/LongitudeTZ/issues)

Patches and enhancements may be submitted via a pull request at [https://github.com/ikluft/LongitudeTZ/pulls](https://github.com/ikluft/LongitudeTZ/pulls)
