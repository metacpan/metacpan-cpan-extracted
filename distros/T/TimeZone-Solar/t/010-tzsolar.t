#!/usr/bin/env perl
# t/010-tzsolar.t - basic tests for TimeZone::Solar
#
# Copyright © 2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2018);
## use critic (Modules::RequireExplicitPackage)

use utf8;
use Carp;
use Test::More;
use Test::Exception;
use Readonly;
use IO::File;
use TimeZone::Solar;

# constants
Readonly::Hash my %constants => (
    PRECISION_DIGITS       => 6,
    PRECISION_FP           => 0.0000005,
    MAX_DEGREES            => 360,
    MAX_LONGITUDE_INT      => 180,
    MAX_LONGITUDE_FP       => 180.0,
    MAX_LATITUDE_FP        => 90.0,
    POLAR_UTC_AREA         => 10,
    LIMIT_LATITUDE         => 80,
    MINUTES_PER_DEGREE_LON => 4,
);
Readonly::Scalar my $debug_mode      => ( exists $ENV{TZSOLAR_DEBUG} and $ENV{TZSOLAR_DEBUG} ) ? 1 : 0;
Readonly::Scalar my $fp_epsilon      => 2**-24;                   # fp epsilon for fp_equal() based on 32-bit floats
Readonly::Scalar my $total_constants => scalar keys %constants;
Readonly::Array my @test_point_longitudes =>
    qw( 180.0 179.99999 -7.5 -7.49999 0.0 7.49999 7.5 -180.0 -179.99999 60.0 90.0 89.5 89.49999 120.0 );
Readonly::Array my @test_point_latitudes => qw( 80.0 79.99999 -80.0 -79.99999 );
Readonly::Array my @polar_test_points    => ( gen_polar_test_points() );

# generate polar test points array
# used to generate @polar_test_points constant listed above
sub gen_polar_test_points
{
    my @polar_test_points;
    foreach my $use_lon_tz (qw( 0 1 )) {
        foreach my $longitude (@test_point_longitudes) {
            foreach my $latitude (@test_point_latitudes) {
                push @polar_test_points, { longitude => $longitude, latitude => $latitude, use_lon_tz => $use_lon_tz };
            }
        }
    }
    return @polar_test_points;
}

# count tests
sub count_tests
{
    return (
        4                                             # in test_functions()
            + $total_constants                        # number of constants, in test_constants()
            + ( $constants{MAX_DEGREES} + 1 ) * 10    # per-degree tests from -180 to +180, in test_lon()
            + ( scalar @polar_test_points )           # in test_polar()
    );
}

# floating point equality comparison utility function
# FP must not be compared with == operator - instead check if difference is within "machine epsilon" precision
sub fp_equal
{
    my ( $x, $y ) = @_;
    return ( abs( $x - $y ) < $fp_epsilon ) ? 1 : 0;
}

# test TimeZone::Solar internal functions
sub test_functions
{
    # tests which throw exceptions
    throws_ok(
        sub { TimeZone::Solar::_class_guard() },
        qr/invalid method call on undefined value/,
        "expected exception: _class_guard(undef)"
    );
    throws_ok(
        sub { TimeZone::Solar::_class_guard("UNIVERSAL") },
        qr/invalid method call for 'UNIVERSAL':/,
        "expected exception: _class_guard(UNIVERSAL)"
    );

    # tests which should not throw exceptions
    my @constant_keys;
    lives_ok( sub { @constant_keys = TimeZone::Solar->_get_const() }, "runs without exception: _get_const()" );
    is_deeply( \@constant_keys, [ sort keys %constants ], "list of constants matches" );
}

# check constants
sub test_constants
{
    foreach my $key ( sort keys %constants ) {
        if ( substr( $key, -3 ) eq "_FP" ) {

            # floating point value
            ok(
                fp_equal( TimeZone::Solar->_get_const($key), $constants{$key} ),
                sprintf( "constant check: %s = %.7f", $key, $constants{$key} )
            );
        } else {

            # other types
            is( TimeZone::Solar->_get_const($key), $constants{$key}, "constant check: $key = $constants{$key}" );
        }
    }
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

# convert offset minutes to string
sub _offset_min2str
{
    my $offset_min = shift;
    my $sign       = $offset_min >= 0 ? "+" : "-";
    my $hours      = int( abs($offset_min) / 60 );
    my $minutes    = abs($offset_min) % 60;
    return sprintf "%s%02d%s%02d", $sign, $hours, ":", $minutes;
}

# compute expected time zone name and offset for test
# parameters use integer degrees and return the expected values at that longitude
# floating point variations on coordinates are up to the tests - but it expects this integer's result
sub expect_lon2tz
{
    my %params          = @_;
    my $lon             = $params{longitude};
    my $precision       = $constants{PRECISION_FP};
    my $use_lon_tz      = ( exists $params{use_lon_tz} and $params{use_lon_tz} );
    my $tz_degree_width = $use_lon_tz ? 1 : 15;    # 1 for longitude-based tz, 15 for hour-based tz
    my $tz_digits       = $use_lon_tz ? 3 : 2;

    # generate time zone name and offset
    my ( $tz_name, $offset_min );
    if (   $lon >= $constants{MAX_LONGITUDE_INT} - $tz_degree_width / 2.0 - $precision
        or $lon <= -$constants{MAX_LONGITUDE_INT} + $precision )
    {

        # handle special case of half-wide tz at positive side of solar date line (180° longitude)
        # special case of -180: expect results for +180
        $tz_name = sprintf( "%s%0*d%s",
            _tz_prefix( $use_lon_tz, 1 ),
            $tz_digits,
            $constants{MAX_LONGITUDE_INT} / $tz_degree_width,
            _tz_suffix( $use_lon_tz, 1 ) );
        $offset_min = 720;
        $debug_mode and say STDERR "debug expect_lon2tz(): tz_name=$tz_name offset_min=$offset_min (case: date line +)";
    } elsif ( $lon <= ( -$constants{MAX_LONGITUDE_INT} + $tz_degree_width / 2.0 + $precision ) ) {

        # handle special case of half-wide tz at negative side of solar date line (180° longitude)
        $tz_name = sprintf( "%s%0*d%s",
            _tz_prefix( $use_lon_tz, -1 ),
            $tz_digits,
            $constants{MAX_LONGITUDE_INT} / $tz_degree_width,
            _tz_suffix( $use_lon_tz, -1 ) );
        $offset_min = -720;
        $debug_mode and say STDERR "debug expect_lon2tz(): tz_name=$tz_name offset_min=$offset_min (case: date line -)";
    } else {

        # handle other times zones
        my $tz_int = int( abs($lon) / $tz_degree_width + 0.5 + $precision );
        my $sign   = ( $lon > -$tz_degree_width / 2.0 + $precision ) ? 1 : -1;
        $tz_name = sprintf( "%s%0*d%s",
            _tz_prefix( $use_lon_tz, $sign ),
            $tz_digits, $tz_int, _tz_suffix( $use_lon_tz, $sign ) );
        $offset_min = $sign * $tz_int * ( $constants{MINUTES_PER_DEGREE_LON} * $tz_degree_width );
        $debug_mode and say STDERR "debug expect_lon2tz(): tz_name=$tz_name offset_min=$offset_min (case: general)";
    }

    my $class      = "DateTime::TimeZone::Solar::" . $tz_name;
    my $offset_str = _offset_min2str($offset_min);
    $debug_mode and say STDERR "debug(lon:$lon,type:" . ( $use_lon_tz ? "lon" : "hour" ) . ") -> $tz_name, $offset_min";
    return ( short_name => $tz_name, offset_min => $offset_min, offset => $offset_str, class => $class );
}

# perform tests for a degree of longitude
sub test_lon
{
    my $lon = shift;

    # hourly and longitude time zones without latitude
    foreach my $use_lon_tz ( 0, 1 ) {
        my $stz      = TimeZone::Solar->new( longitude => $lon, use_lon_tz => $use_lon_tz );
        my %expected = expect_lon2tz( longitude => $lon, use_lon_tz => $use_lon_tz );
        isa_ok( $stz, $expected{class} );
        is( $stz->short_name(), $expected{short_name},
            sprintf( "lon: %-04d short name = %s", $lon, $expected{short_name} ) );
        is(
            $stz->long_name(),
            "Solar/" . $expected{short_name},
            sprintf( "lon: %-04d long name = %s", $lon, "Solar/" . $expected{short_name} )
        );
        is( $stz->offset_min(), $expected{offset_min},
            sprintf( "lon: %-04d offset_min = %d", $lon, $expected{offset_min} ) );
        is( $stz->offset(), $expected{offset}, sprintf( "lon: %-04d offset = %s", $lon, $expected{offset} ) );
    }
    return;
}

# check against every integer longitude value around the globe
sub test_global
{
    for ( my $lon = -180 ; $lon <= 180 ; $lon++ ) {
        test_lon($lon);
    }
    return;
}

# tests for polar latitudes
# tests border cases - not needed at every degree of longitude
sub test_polar
{
    my $precision = $constants{PRECISION_FP};
    foreach my $test_point (@polar_test_points) {
        my $use_lon =
            ( abs( $test_point->{latitude} ) <= $constants{LIMIT_LATITUDE} - $precision )
            ? $test_point->{longitude}
            : 0;
        my %expected  = expect_lon2tz( longitude => $use_lon, use_lon_tz => $test_point->{use_lon_tz} );
        my $test_name = sprintf(
            "longitude=%-10s latitude=%-9s use_lon_tz=%d",
            $test_point->{longitude},
            $test_point->{latitude},
            $test_point->{use_lon_tz}
            )
            . " => ("
            . join( " ", map { $expected{$_} } sort keys %expected ) . ")";
        my $stz          = TimeZone::Solar->new(%$test_point);
        my $expect_class = "DateTime::TimeZone::Solar::" . $stz->short_name();
        is_deeply(
            {
                short_name => $stz->short_name(),
                offset_min => $stz->offset_min(),
                offset     => $stz->offset(),
                class      => $expect_class
            },
            \%expected,
            $test_name
        );
    }
    return;
}

# main
plan tests => count_tests();
autoflush STDOUT 1;
test_functions();
test_constants();
test_global();
test_polar();
