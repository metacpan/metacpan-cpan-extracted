#!/usr/bin/env perl
# t/011-datetime.t - test TimeZone::Solar compliance with DateTime's time zone interface
# tests adapted from DateTime::TimeZone::LMT because - we do similar solar conversions, but on discrete time zones
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
use DateTime;
use DateTime::TimeZone;

#use Data::Dumper;

# constants
Readonly::Scalar my $debug_mode => ( exists $ENV{TZSOLAR_DEBUG} and $ENV{TZSOLAR_DEBUG} ) ? 1 : 0;
Readonly::Scalar my $total_tests => 29    # base
    + 14 * 4                              # name validity checks
    + 5                                   # Solar timezones found by name in DateTime
    ;
Readonly::Scalar my $test_year => 2022;
Readonly::Array my @test_timestamp => ( year => $test_year, month => 11, day => 28, hour => 1, );
Readonly::Array my @test_params => ( [ longitude => 150, use_lon_tz => 0 ], [ longitude => 150, use_lon_tz => 1 ], );

# tests
sub run_tests_from_lmt
{
    my $TZ_Solar = TimeZone::Solar->new( longitude => 150 );
    $debug_mode and print STDERR "debug: TZ_Solar offset " . $TZ_Solar->offset_str() . "\n";
    my $tz_name = $TZ_Solar->name();
    my $dt;

    eval { $dt = DateTime->now( time_zone => $TZ_Solar ) };
    is( $@, '', "call DateTime->now with $tz_name" );

    eval { $dt->add( years => 50 ) };
    is( $@, '', "add 50 years" );

    eval { $dt->subtract( years => 400 ) };
    is( $@, '', "subtract 400 years" );

    eval { $dt = DateTime->new( year => $test_year, month => 6, hour => 1, time_zone => $TZ_Solar ) };
    is( $@,        '', 'local time is always respected' );
    is( $dt->hour, 1,  'local time is always respected' );

    eval { $dt = DateTime->new( year => $test_year, month => 12, hour => 1, time_zone => $TZ_Solar ) };
    is( $@,        '', 'local time is always respected' );
    is( $dt->hour, 1,  'local time is always respected' );

    eval { $dt = DateTime->new( @test_timestamp, time_zone => 'Australia/Melbourne', )->set_time_zone($TZ_Solar); };
    is( $@,        '', "convert to $tz_name" );
    is( $dt->hour, 0,  "convert to $tz_name" );

    my $melb = DateTime::TimeZone->new( name => 'Australia/Melbourne' );
    $debug_mode and print STDERR "debug: melb tz offset " . $melb->offset_for_datetime($dt) . "\n";

    eval { $dt = DateTime->new( @test_timestamp, time_zone => $TZ_Solar, )->set_time_zone($melb); };
    is( $@,        '', "convert from $tz_name (object) to Olson (object)" );
    is( $dt->hour, 2,  "convert from $tz_name (object) to Olson (object)" );

    eval { $dt = DateTime->new( @test_timestamp, time_zone => $TZ_Solar, )->set_time_zone('Australia/Melbourne'); };
    is( $@,        '', "convert from $tz_name (object) to Olson (name)" );
    is( $dt->hour, 2,  "convert from $tz_name (object) to Olson (name)" );

    eval { $dt = DateTime->new( @test_timestamp, time_zone => "$tz_name", )->set_time_zone($melb); };
    is( $@,        '', "convert from $tz_name (name) to Olson (object)" );
    is( $dt->hour, 2,  "convert from $tz_name (name) to Olson (object)" );

    eval { $dt = DateTime->new( @test_timestamp, time_zone => "$tz_name", )->set_time_zone('Australia/Melbourne'); };
    is( $@,        '', "convert from $tz_name (name) to Olson (name)" );
    is( $dt->hour, 2,  "convert from $tz_name (name) to Olson (name)" );

    my $float = DateTime::TimeZone->new( name => 'floating' );

    eval { $dt = DateTime->new( @test_timestamp, time_zone => $TZ_Solar, )->set_time_zone($float); };
    is( $@,        '', "convert from $tz_name (object) to Floating (object)" );
    is( $dt->hour, 1,  "convert from $tz_name (object) to Floating (object)" );

    eval { $dt = DateTime->new( @test_timestamp, time_zone => $TZ_Solar, )->set_time_zone('floating'); };
    is( $@,        '', "convert from $tz_name (object) to Floating (name)" );
    is( $dt->hour, 1,  "convert from $tz_name (object) to Floating (name)" );

    eval { $dt = DateTime->new( @test_timestamp, time_zone => "$tz_name", )->set_time_zone($float); };
    is( $@,        '', "convert from $tz_name (name) to Floating (object)" );
    is( $dt->hour, 1,  "convert from $tz_name (name) to Floating (object)" );

    eval { $dt = DateTime->new( @test_timestamp, time_zone => "$tz_name", )->set_time_zone('floating'); };
    is( $@,        '', "convert from $tz_name (name) to Floating (name)" );
    is( $dt->hour, 1,  "convert from $tz_name (name) to Floating (name)" );

    eval {
        $dt = DateTime->new( @test_timestamp, time_zone => $TZ_Solar, )->set_time_zone('floating')
            ->set_time_zone('Australia/Melbourne');
    };
    is( $@,        '', "convert from $tz_name to Floating to Olson" );
    is( $dt->hour, 1,  "convert from $tz_name to Floating to Olson" );

    eval { $dt = DateTime->new( @test_timestamp, time_zone => $TZ_Solar, )->set_time_zone('UTC'); };
    is( $@,        '', "convert from $tz_name to UTC" );
    is( $dt->hour, 15, "convert from $tz_name to UTC" );

    return;
}

# run a single validity test
sub run_validity_test_lon
{
    my $lon = shift;
    foreach my $use_lon_tz ( 0 .. 1 ) {
        my $stz = TimeZone::Solar->new( longitude => $lon, use_lon_tz => $use_lon_tz );
        foreach my $name ( $stz->long_name(), $stz->short_name() ) {
            ok( DateTime::TimeZone->is_valid_name($name), "DateTime::TimeZone recognizes $name" );
        }
    }
    return;
}

# check the DateTime::TimeZone recognizes the Solar times zones as valid
sub run_validity_tests
{
    foreach my $lon1 (qw( -180 -179.75 )) {
        run_validity_test_lon($lon1);
    }
    for ( my $lon2 = -179 ; $lon2 <= 180 ; $lon2 += 30 ) {
        run_validity_test_lon($lon2);
    }
    return;
}

# verify that Solar timezones work with DateTime after TimeZone::Solar is loaded, without instantiating it first
sub run_dt_solartz
{
    my ( $dt, $dt_hour, $dt_min );
    my $tz_name_hour = "Solar/West08";    # hour-based time zone, same as US Pacific Standard Time
    eval { $dt = DateTime->new( year => $test_year, month => 6, hour => 1, time_zone => $tz_name_hour ) };
    is( $@, '', 'dt with solar time zone not previously instantiated: no errors' );
    $dt_hour = ( ( defined $dt ) and $dt->hour );
    is( $dt_hour, 1, 'dt with solar time zone not previously instantiated: hour = 1' );

    my $tz_name_lon = "Solar/Lon122W";    # longitude-based time zone of San Jose CA or Seattle WA
    eval { $dt = DateTime->new( @test_timestamp, time_zone => "$tz_name_hour", )->set_time_zone($tz_name_lon); };
    is( $@, '', "convert from $tz_name_hour (name) to $tz_name_lon (name): no errors" );
    $dt_hour = ( ( defined $dt ) and $dt->hour );
    $dt_min  = ( ( defined $dt ) and $dt->minute );
    is( $dt_hour, 0,  "convert from $tz_name_hour (name) to $tz_name_lon (name): hour = 0" );
    is( $dt_min,  52, "convert from $tz_name_hour (name) to $tz_name_lon (name): minute = 52" );

    #$debug_mode and print STDERR "debug(run_dt_solartz): dt = ".Dumper($dt);

    return;
}

# main
plan tests => $total_tests;
autoflush STDOUT 1;
run_tests_from_lmt();
run_validity_tests();
run_dt_solartz();
