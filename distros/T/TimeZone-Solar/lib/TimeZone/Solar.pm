# TimeZone::Solar
# ABSTRACT: local solar timezone lookup and utilities including DateTime compatibility
# part of Perl implementation of solar timezones library
#
# Copyright © 2020-2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

package TimeZone::Solar;
$TimeZone::Solar::VERSION = '0.2.0';
use utf8;
use autodie;
use overload
    '""' => "as_string",
    'eq' => "eq_string";
use Carp qw(croak);
use Readonly;
use DateTime::TimeZone qw(0.80);
use Try::Tiny;

# constants
Readonly::Scalar my $debug_mode           => ( exists $ENV{TZSOLAR_DEBUG} and $ENV{TZSOLAR_DEBUG} ) ? 1 : 0;
Readonly::Scalar my $TZSOLAR_CLASS_PREFIX => "DateTime::TimeZone::Solar::";
Readonly::Scalar my $TZSOLAR_LON_ZONE_RE  => qr((Lon0[0-9][0-9][EW]) | (Lon1[0-7][0-9][EW]) | (Lon180[EW]))x;
Readonly::Scalar my $TZSOLAR_HOUR_ZONE_RE => qr((East|West)(0[0-9] | 1[0-2]))x;
Readonly::Scalar my $TZSOLAR_ZONE_RE      => qr( $TZSOLAR_LON_ZONE_RE | $TZSOLAR_HOUR_ZONE_RE )x;
Readonly::Scalar my $PRECISION_DIGITS  => 6;                                  # max decimal digits of precision
Readonly::Scalar my $PRECISION_FP      => ( 10**-$PRECISION_DIGITS ) / 2.0;   # 1/2 width of floating point equality
Readonly::Scalar my $MAX_DEGREES       => 360;                                # maximum degrees = 360
Readonly::Scalar my $MAX_LONGITUDE_INT => $MAX_DEGREES / 2;                   # min/max longitude in integer = 180
Readonly::Scalar my $MAX_LONGITUDE_FP  => $MAX_DEGREES / 2.0;                 # min/max longitude in float = 180.0
Readonly::Scalar my $MAX_LATITUDE_FP   => $MAX_DEGREES / 4.0;                 # min/max latitude in float = 90.0
Readonly::Scalar my $POLAR_UTC_AREA    => 10;                                 # latitude degrees around poles to use UTC
Readonly::Scalar my $LIMIT_LATITUDE    => $MAX_LATITUDE_FP - $POLAR_UTC_AREA; # max latitude for solar time zones
Readonly::Scalar my $MINUTES_PER_DEGREE_LON => 4;                             # minutes per degree longitude
Readonly::Hash my %constants => (                                             # allow tests to check constants
    PRECISION_DIGITS       => $PRECISION_DIGITS,
    PRECISION_FP           => $PRECISION_FP,
    MAX_DEGREES            => $MAX_DEGREES,
    MAX_LONGITUDE_INT      => $MAX_LONGITUDE_INT,
    MAX_LONGITUDE_FP       => $MAX_LONGITUDE_FP,
    MAX_LATITUDE_FP        => $MAX_LATITUDE_FP,
    POLAR_UTC_AREA         => $POLAR_UTC_AREA,
    LIMIT_LATITUDE         => $LIMIT_LATITUDE,
    MINUTES_PER_DEGREE_LON => $MINUTES_PER_DEGREE_LON,
);

# create timezone subclass
# this must be before the BEGIN block which uses it
sub _tz_subclass
{
    my ( $class, %opts ) = @_;

    # for test coverage: if $opts{test_break_eval} is set, break the eval below
    # under normal circumstances, %opts parameters should be omitted
    my $result_cmd = (
        ( exists $opts{test_break_eval} and $opts{test_break_eval} )
        ? "croak 'break due to test_break_eval'"    # for testing we can force the eval to break
        : "1"                                       # normally the class definition returns 1
    );

    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    my $class_check = 0;
    try {
        $class_check =
              eval "package $class {" . "\@"
            . $class
            . "::ISA = qw("
            . __PACKAGE__ . ");" . "\$"
            . $class
            . "::VERSION = \$"
            . __PACKAGE__
            . "::VERSION;"
            . "$result_cmd; " . "}";
    };
    if ( not $class_check ) {
        croak __PACKAGE__ . "::_tz_subclass: unable to create class $class";
    }

    # generate class file path for use in %INC so require() considers this class loaded
    my $classpath = $class;
    $classpath =~ s/::/\//gx;
    $classpath .= ".pm";
    ## no critic ( Variables::RequireLocalizedPunctuationVars) # this must be global to work
    $INC{$classpath} = 1;
    return;
}

# create subclasses for DateTime::TimeZone::Solar::* time zones
# Set subclass @ISA to point here as its parent. Then the subclass inherits methods from this class.
# This modifies %DateTime::TimeZone::Catalog::LINKS the same way it allows DateTime::TimeZone::Alias to.
BEGIN {
    # duplicate constant within BEGIN scope because it runs before constant assignments
    Readonly::Scalar my $TZSOLAR_CLASS_PREFIX => "DateTime::TimeZone::Solar::";

    # hour-based timezones from -12 to +12
    foreach my $tz_dir (qw( East West )) {
        foreach my $tz_int ( 0 .. 12 ) {
            my $short_name = sprintf( "%s%02d", $tz_dir, $tz_int );
            my $long_name  = "Solar/" . $short_name;
            my $class_name = $TZSOLAR_CLASS_PREFIX . $short_name;
            _tz_subclass($class_name);
            $DateTime::TimeZone::Catalog::LINKS{$short_name} = $long_name;
        }
    }

    # longitude-based time zones from -180 to +180
    foreach my $tz_dir (qw( E W )) {
        foreach my $tz_int ( 0 .. 180 ) {
            my $short_name = sprintf( "Lon%03d%s", $tz_int, $tz_dir );
            my $long_name  = "Solar/" . $short_name;
            my $class_name = $TZSOLAR_CLASS_PREFIX . $short_name;
            _tz_subclass($class_name);
            $DateTime::TimeZone::Catalog::LINKS{$short_name} = $long_name;
        }
    }
}

# file globals
my %_INSTANCES;

# enforce class access
sub _class_guard
{
    my $class     = shift;
    my $classname = ref $class ? ref $class : $class;
    if ( not defined $classname ) {
        croak("incompatible class: invalid method call on undefined value");
    }
    if ( not $class->isa(__PACKAGE__) ) {
        croak( "incompatible class: invalid method call for '$classname': not in " . __PACKAGE__ . " hierarchy" );
    }
    return;
}

# Override isa() method from UNIVERSAL to trick DateTime::TimeZone to accept our timezones as its subclasses.
# We don't inherit from DateTime::TimeZone as a base class because it's about Olson TZ db processing we don't need.
# But DateTime uses DateTime::TimeZone to look up time zones, and this makes solar timezones fit in.
## no critic ( Subroutines::ProhibitBuiltinHomonyms )
sub isa
{
    my ( $class, $type ) = @_;
    if ( $type eq "DateTime::TimeZone" ) {
        return 1;
    }
    return $class->SUPER::isa($type);
}
## critic ( Subroutines::ProhibitBuiltinHomonyms )

# access constants - for use by tests
# if no name parameter is provided, return list of constant names
# throws exception if requested contant name doesn't exist
## no critic ( Subroutines::ProhibitUnusedPrivateSubroutines )
sub _get_const
{
    my @args = @_;
    my ( $class, $name ) = @args;
    _class_guard($class);

    # if no name provided, return list of keys
    if ( scalar @args <= 1 ) {
        return ( sort keys %constants );
    }

    # require valid name parameter
    if ( not exists $constants{$name} ) {
        croak "non-existent constant requested: $name";
    }
    return $constants{$name};
}
## critic ( Subroutines::ProhibitUnusedPrivateSubroutines )

# return TimeZone::Solar (or subclass) version number
sub version
{
    my $class = shift;
    _class_guard($class);

    {
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        if ( defined ${ $class . "::VERSION" } ) {
            return ${ $class . "::VERSION" };
        }
    }
    return "00-dev";
}

# check latitude data and initialize special case for polar regions - internal method called by init()
sub _tz_params_latitude
{
    my $param_ref = shift;

    # safety check on latitude
    if ( not $param_ref->{latitude} =~ /^[-+]?\d+(\.\d+)?$/x ) {
        croak( __PACKAGE__ . "::_tz_params_latitude: latitude '" . $param_ref->{latitude} . "' is not numeric" );
    }
    if ( abs( $param_ref->{latitude} ) > $MAX_LATITUDE_FP + $PRECISION_FP ) {
        croak __PACKAGE__ . "::_tz_params_latitude: latitude when provided must be in range -90..+90";
    }

    # special case: use East00/Lon000E (equal to UTC) within 10° latitude of poles
    if ( abs( $param_ref->{latitude} ) >= $LIMIT_LATITUDE - $PRECISION_FP ) {
        my $use_lon_tz = ( exists $param_ref->{use_lon_tz} and $param_ref->{use_lon_tz} );
        $param_ref->{short_name} = $use_lon_tz ? "Lon000E" : "East00";
        $param_ref->{name}       = "Solar/" . $param_ref->{short_name};
        $param_ref->{offset_min} = 0;
        $param_ref->{offset}     = _offset_min2str(0);
        return $param_ref;
    }
    return;
}

# formatting functions
sub _tz_prefix
{
    my ( $use_lon_tz, $sign ) = @_;
    return $use_lon_tz ? "Lon" : ( $sign > 0 ? "East" : "West" );
}

sub _tz_suffix
{
    my ( $use_lon_tz, $sign ) = @_;
    return $use_lon_tz ? ( $sign > 0 ? "E" : "W" ) : "";
}

# get timezone parameters (name and minutes offset) - called by new()
sub _tz_params
{
    my %params = @_;
    if ( not exists $params{longitude} ) {
        croak __PACKAGE__ . "::_tz_params: longitude parameter missing";
    }

    # if latitude is provided, use UTC within 10° latitude of poles
    if ( exists $params{latitude} ) {

        # check latitude data and special case for polar regions
        my $lat_params = _tz_params_latitude( \%params );

        # return if initialized, otherwise fall through to set time zone from longitude as usual
        return $lat_params
            if ref $lat_params eq "HASH";
    }

    #
    # set time zone from longitude
    #

    # safety check on longitude
    if ( not $params{longitude} =~ /^[-+]?\d+(\.\d+)?$/x ) {
        croak( __PACKAGE__ . "::_tz_params: longitude '" . $params{longitude} . "' is not numeric" );
    }
    if ( abs( $params{longitude} ) > $MAX_LONGITUDE_FP + $PRECISION_FP ) {
        croak __PACKAGE__ . "::_tz_params: longitude must be in the range -180 to +180";
    }

    # set flag for longitude time zones: 0 = hourly 1-hour/15-degree zones, 1 = longitude 4-minute/1-degree zones
    # defaults to hourly time zone ($use_lon_tz=0)
    my $use_lon_tz      = ( exists $params{use_lon_tz} and $params{use_lon_tz} );
    my $tz_degree_width = $use_lon_tz ? 1 : 15;    # 1 for longitude-based tz, 15 for hour-based tz
    my $tz_digits       = $use_lon_tz ? 3 : 2;

    # handle special case of half-wide tz at positive side of solar date line (180° longitude)
    if (   $params{longitude} >= $MAX_LONGITUDE_INT - $tz_degree_width / 2.0 - $PRECISION_FP
        or $params{longitude} <= -$MAX_LONGITUDE_INT + $PRECISION_FP )
    {
        my $tz_name = sprintf "%s%0*d%s",
            _tz_prefix( $use_lon_tz, 1 ),
            $tz_digits, $MAX_LONGITUDE_INT / $tz_degree_width,
            _tz_suffix( $use_lon_tz, 1 );
        $params{short_name} = $tz_name;
        $params{name}       = "Solar/" . $tz_name;
        $params{offset_min} = 720;
        $params{offset}     = _offset_min2str(720);
        return \%params;
    }

    # handle special case of half-wide tz at negativ< side of solar date line (180° longitude)
    if ( $params{longitude} <= -$MAX_LONGITUDE_INT + $tz_degree_width / 2.0 + $PRECISION_FP ) {
        my $tz_name = sprintf "%s%0*d%s",
            _tz_prefix( $use_lon_tz, -1 ),
            $tz_digits, $MAX_LONGITUDE_INT / $tz_degree_width,
            _tz_suffix( $use_lon_tz, -1 );
        $params{short_name} = $tz_name;
        $params{name}       = "Solar/" . $tz_name;
        $params{offset_min} = -720;
        $params{offset}     = _offset_min2str(-720);
        return \%params;
    }

    # handle other times zones
    my $tz_int  = int( abs( $params{longitude} ) / $tz_degree_width + 0.5 + $PRECISION_FP );
    my $sign    = ( $params{longitude} > -$tz_degree_width / 2.0 + $PRECISION_FP ) ? 1 : -1;
    my $tz_name = sprintf "%s%0*d%s",
        _tz_prefix( $use_lon_tz, $sign ),
        $tz_digits, $tz_int,
        _tz_suffix( $use_lon_tz, $sign );
    my $offset = $sign * $tz_int * ( $MINUTES_PER_DEGREE_LON * $tz_degree_width );
    $params{short_name} = $tz_name;
    $params{name}       = "Solar/" . $tz_name;
    $params{offset_min} = $offset;
    $params{offset}     = _offset_min2str($offset);
    return \%params;
}

# get timezone instance
sub _tz_instance
{
    my $hashref = shift;

    # consistency checks
    if ( not defined $hashref ) {
        croak __PACKAGE__ . "::_tz_instance: object not found in parameters";
    }
    if ( ref $hashref ne "HASH" ) {
        croak __PACKAGE__ . "::_tz_instance: received non-hash " . ( ref $hashref ) . " for object";
    }
    if ( not exists $hashref->{short_name} ) {
        croak __PACKAGE__ . "::_tz_instance: short_name attribute missing";
    }
    if ( $hashref->{short_name} !~ $TZSOLAR_ZONE_RE ) {
        croak __PACKAGE__
            . "::_tz_instance: short_name attrbute "
            . $hashref->{short_name}
            . " is not a valid Solar timezone";
    }

    # look up class instance, return it if found
    my $class = $TZSOLAR_CLASS_PREFIX . $hashref->{short_name};
    if ( exists $_INSTANCES{$class} ) {

        # forward lat/lon parameters to the existing instance, mainly so tests can see where it came from
        foreach my $key (qw(longitude latitude)) {
            if ( exists $hashref->{$key} ) {
                $_INSTANCES{$class}->{$key} = $hashref->{$key};
            } else {
                delete $_INSTANCES{$class}->{$key};
            }
        }
        return $_INSTANCES{$class};
    }

    # make sure the new singleton object's class is a subclass of TimeZone::Solar
    # this should have already been done by the BEGIN block for all solar timezone subclasses
    if ( not $class->isa(__PACKAGE__) ) {
        _tz_subclass($class);
    }

    # bless the new object into the timezone subclass and save the singleton instance
    my $obj = bless $hashref, $class;
    $_INSTANCES{$class} = $obj;

    # return the new object
    return $obj;
}

# instantiate a new TimeZone::Solar object
sub new
{
    my ( $in_class, %args ) = @_;
    my $class = ref($in_class) || $in_class;

    # safety check
    if ( not $class->isa(__PACKAGE__) ) {
        croak __PACKAGE__ . "->new() prohibited for unrelated class $class";
    }

    # if we got here via DataTime::TimeZone::Solar::*->new(), override longitude/use_lon_tz parameters from class name
    if ( $in_class =~ qr( $TZSOLAR_CLASS_PREFIX ( $TZSOLAR_ZONE_RE ))x ) {
        my $in_tz = $1;
        if ( substr( $in_tz, 0, 4 ) eq "East" ) {
            my $tz_int = int substr( $in_tz, 4, 2 );
            $args{longitude}  = $tz_int * 15;
            $args{use_lon_tz} = 0;
        } elsif ( substr( $in_tz, 0, 4 ) eq "West" ) {
            my $tz_int = int substr( $in_tz, 4, 2 );
            $args{longitude}  = -$tz_int * 15;
            $args{use_lon_tz} = 0;
        } elsif ( substr( $in_tz, 0, 3 ) eq "Lon" ) {
            my $tz_int = int substr( $in_tz, 3, 3 );
            my $sign   = ( substr( $in_tz, 6, 1 ) eq "E" ? 1 : -1 );
            $args{longitude}  = $sign * $tz_int;
            $args{use_lon_tz} = 1;
        } else {
            croak __PACKAGE__ . "->new() received unrecognized class name $in_class";
        }
        delete $args{latitude};
    }

    # use %args to look up a timezone singleton instance
    # make a new one if it doesn't yet exist
    my $tz_params = _tz_params(%args);
    my $self      = _tz_instance($tz_params);

    # use init() method, with support for derived classes that may override it
    if ( my $init_func = $self->can("init") ) {
        $init_func->($self);
    }
    return $self;
}

#
# accessor methods
#

# longitude: read-only accessor
sub longitude
{
    my $self = shift;
    return $self->{longitude};
}

# latitude read-only accessor
sub latitude
{
    my $self = shift;
    return if not exists $self->{latitude};
    return $self->{latitude};
}

# name: read accessor
sub name
{
    my $self = shift;
    return $self->{name};
}

# short_name: read accessor
sub short_name
{
    my $self = shift;
    return $self->{short_name};
}

# long_name: read accessor
sub long_name { my $self = shift; return $self->name(); }

# offset read accessor
sub offset
{
    my $self = shift;
    return $self->{offset};
}

# offset_min read accessor
sub offset_min
{
    my $self = shift;
    return $self->{offset_min};
}

#
# conversion functions
#

# convert offset minutes to string
sub _offset_min2str
{
    my $offset_min = shift;
    my $sign       = $offset_min >= 0 ? "+" : "-";
    my $hours      = int( abs($offset_min) / 60 );
    my $minutes    = abs($offset_min) % 60;
    return sprintf "%s%02d%s%02d", $sign, $hours, ":", $minutes;
}

# offset minutes as string
sub offset_str
{
    my $self = shift;
    return $self->{offset};
}

# convert offset minutes to seconds
sub offset_sec
{
    my $self = shift;
    return $self->{offset_min} * 60;
}

#
# DateTime::TimeZone interface compatibility methods
# By definition, there is never a Daylight Savings change in the Solar time zones.
#
sub spans                     { return []; }
sub has_dst_changes           { return 0; }
sub is_floating               { return 0; }
sub is_olson                  { return 0; }
sub category                  { return "Solar"; }
sub is_utc                    { my $self = shift; return $self->{offset_min} == 0 ? 1 : 0; }
sub is_dst_for_datetime       { return 0; }
sub offset_for_datetime       { my $self = shift; return $self->offset_sec(); }
sub offset_for_local_datetime { my $self = shift; return $self->offset_sec(); }
sub short_name_for_datetime   { my $self = shift; return $self->short_name(); }

# instance method to respond to DateTime::TimeZone as it expects its timezone subclasses to
sub instance
{
    my ( $class, %args ) = @_;
    _class_guard($class);
    delete $args{is_olson};    # never accept the is_olson attribute since it isn't true for solar timezones
    return $class->new(%args);
}

# convert to string for printing
# used to overload "" (to string) operator
sub as_string
{
    my $self = shift;
    return $self->name() . " " . $self->offset();
}

# equality comparison
# used to overload eq (string equality) operator
sub eq_string
{
    my ( $self, $arg ) = @_;
    if ( ref $arg and $arg->isa(__PACKAGE__) ) {
        return $self->name eq $arg->name;
    }
    return $self->name eq $arg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TimeZone::Solar - local solar timezone lookup and utilities including DateTime compatibility

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

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

=head1 DESCRIPTION

I<TimeZone::Solar> provides lookup and conversion utilities for Solar time zones, which are based on
the longitude of any location on Earth. See the next subsection below for more information.

Through compatibility with L<DateTime::TimeZone>, I<TimeZone::Solar> allows the L<DateTime> module to
convert either direction between standard (Olson Database) timezones and Solar time zones.

=head2 Overview of Solar time zones

Solar time zones are based on the longitude of a location.  Each time zone is defined around having
local solar noon, on average, the same as noon on the clock.

Solar time zones are always in Standard Time. There are no Daylight Time changes, by definition. The main point
is to have a way to opt out of Daylight Saving Time by using solar time.

The Solar time zones build upon existing standards.

=over

=item *
Lines of longitude are a well-established standard.

=item *
Ships at sea use "nautical time" based on time zones 15 degrees of longitude wide.

=item *
Time zones (without daylight saving offsets) are based on average solar noon at the Prime Meridian. Standard Time in
each time zone lines up with average solar noon on the meridian at the center of each time zone, at 15-degree of
longitude increments.

=back

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

=head2 Definition of Solar time zones

The Solar time zones definition includes the following rules.

=over

=item *
There are 24 hour-based Solar Time Zones, named West12, West11, West10, West09 through East12. East00 is equivalent to UTC. West00 is an alias for East00.

=over

=item *
Hour-based time zones are spaced in one-hour time increments, or 15 degrees of longitude.

=item *
Each hour-based time zone is centered on a meridian at a multiple of 15 degrees. In positive and negative integers, these are 0, 15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165 and 180.

=item *
Each hour-based time zone spans the area ±7.5 degrees of longitude either side of its meridian.

=back

=item *
There are 360 longitude-based Solar Time Zones, named Lon180W for 180 degrees West through Lon180E for 180 degrees East. Lon000E is equivalent to UTC. Lon000W is an alias for Lon000E.

=over

=item *
Longitude-based time zones are spaced in 4-minute time increments, or 1 degree of longitude.

=item *
Each longitude-based time zone is centered on the meridian of an integer degree of longitude.

=item *
Each longitude-based time zone spans the area ±0.5 degrees of longitude either side of its meridian.

=back

=item *
In both hourly and longitude-based time zones, there is a limit to their usefulness at the poles. Beyond 80 degrees north or south, the definition uses UTC (East00 or Lon000E). This boundary is the only reason to include latitude in the computation of the time zone.

=item *
When converting coordinates to a time zone, each time zone includes its boundary meridian at the lower end of its absolute value, which is in the direction toward 0 (UTC). The exception is at exactly ±180.0 degrees, which would be excluded from both sides by this rule. That case is arbitrarily set as +180 just to pick one.

=item *
The category "Solar" is used for the longer names for these time zones. The names listed above are the short names. The full long name of each time zone is prefixed with "Solar/" such as "Solar/East00" or "Solar/Lon000E".

=back

=head1 FUNCTIONS AND METHODS

=head2 Class methods

=over

=item $obj = TimeZone::Solar->new( longitude => $float, use_lon_tz => $bool, [latitude => $float] )

Create a new instance of the time zone for the given longitude as a floating point number. The "use_lon_tz" parameter
is a boolean flag which if true selects longitude-based time zones, at a width of 1 degree of longitude. If false or
omitted, it selects hour-based time zones, at a width of 15 degrees of longitude.

If a latitude parameter is provided, it only makes a difference if the latitude is within 10° of the poles,
at or beyond 80° North or South latitude. In the polar regions, it uses the equivalent of UTC, which is Solar/East00
for hour-based time zones or Solar/Lon000E for longitude-based time zones.

I<TimeZone::Solar> uses a singleton pattern. So if a given solar time zone's class within the
I<DateTime::TimeZone::Solar::*> hierarchy already has an instance, that one will be returned.
A new instance is only returned the first time.

=item $obj = DateTime::TimeZone::Solar::I<timezone>->new()

This is the same class method as TimeZone::Solar->new() except that if called with a class in the
I<DateTime::TimeZone::Solar::*> hierarchy, it obtains the time zone parameters from the class name.
If an instance exists for that solar time zone class, then that instance is returned.
If not, a new one is instantiated and returned.

=item $obj = DateTime::TimeZone::Solar::I<timezone>->instance()

For compatibility with I<DateTime::TimeZone>, the instance() method returns the class' instance if it exists.
Otherwise it is created using the class name to fill in its parameters via the new() method.

=item TimeZone::Solar->version()

Return the version number of TimeZone::Solar, or for any subclass which inherits the method.

When running code within a source-code development workspace, it returns "00-dev" to avoid warnings
about undefined values.
Release version numbers are assigned and added by the build system upon release,
and are not available when running directly from a source code repository.

=back

=head2 instance methods

=over

=item $obj->longitude()

returns the longitude which was used to instantiate the time zone object.
This is mainly intended for testing. Once instantiated the time zone object serves all areas in its boundary.

=item $obj->latitude()

returns the latitude which was used to instantiate the time zone object, or undef if none was provided.
This is mainly intended for testing. Once instantiated the time zone object serves all areas in its boundary.

=item $obj->name()

returns a string with the long name, including the "Solar/" prefix, of the time zone.

=item $obj->long_name()

returns a string with the long name, including the "Solar/" prefix, of the time zone.
This is equivalent to $obj->name().

=item $obj->short_name()

returns a string with the short name, excluding the "Solar/" prefix, of the time zone.

=item $obj->offset()

returns a string with the time zone's offset from UTC in hour-minute format like +01:01 or -01:01 .
If seconds matter, it will include them in the format +01:01:01 or -01:01:01 .

=item $obj->offset_str()

returns a string with the time zone's offset from UTC in hour-minute format, equivalent to $obj->offset().

=item $obj->offset_min()

returns an integer with the number of minutes of the time zone's offest from UTC.

=item $obj->offset_sec()

returns an integer with the number of seconds of the time zone's offest from UTC.

=back

=head2 DateTime::TimeZone compatibility methods

=over

=item spans()

always returns an empty list because there are never any Daylight Time transitions in solar time zones.

=item has_dst_changes()

always returns 0 (false) because there are never any Daylight Time transitions in solar time zones.

=item is_floating()

always returns 0 (false) because the solar time zones are not floating time zones.

=item is_olson()

always returns 0 (false) because the solar time zones are not in the Olson time zone database.
(Maybe some day.)

=item category()

always returns "Solar" for the time zone category.

=item is_utc()

Returns 1 (true) if the time zone is equivalent to UTC, meaning at 0 offset from UTC. This is only the case for
Solar/East00, Solar/West00 (which is an alias for Solar/East00), Solar/Lon000E and Solar/Lon000W (which is an alias
for Solar/Lon000E). Otherwise it returns 0 because the time zone is not UTC.

=item is_dst_for_datetime()

always returns 0 (false) because Daylight Saving Time never occurs in Solar time zones.

=item offset_for_datetime()

returns the time zone's offset from UTC in seconds. This is equivalent to $obj->offset_sec().

=item offset_for_local_datetime()

returns the time zone's offset from UTC in seconds. This is equivalent to $obj->offset_sec().

=item short_name_for_datetime()

returns the time zone's short name, without "Solar/". This is equivalent to $obj->short_name().

=back

I<TimeZone::Solar> also overloads the eq (string equality) and "" (convert to string) operators for
compatibility with I<DateTime::TimeZone>.

=head1 LICENSE

I<TimeZone::Solar> is Open Source software licensed under the GNU General Public License Version 3.
See L<https://www.gnu.org/licenses/gpl-3.0-standalone.html>.

=head1 SEE ALSO

LongitudeTZ on Github: https://github.com/ikluft/LongitudeTZ

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/LongitudeTZ/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/LongitudeTZ/pulls>

=head1 AUTHOR

Ian Kluft <ian.kluft+github@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ian Kluft.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
