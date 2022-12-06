#!/usr/bin/env perl
# t/002-basic.t - basic tests for TimeZone::Solar, adapted from DateTime::TimeZone::LMT tests
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
use DateTime;
use TimeZone::Solar;

# constants
Readonly::Scalar my $tests_per_cycle => 13;
Readonly::Scalar my $tz_degree_width => 15;
Readonly::Scalar my $date_jan        => DateTime->new( year => 2023, month => 1, day => 1 );
Readonly::Scalar my $date_jul        => DateTime->new( year => 2023, month => 7, day => 1 );

# basic test loop
sub run_tests
{
    for ( my $long = -180 ; $long <= 180 ; $long += 30 ) {
        my $use_long = $long;
        if ( $long == -180 ) {
            $use_long = 180;
        }
        my $tz         = TimeZone::Solar->new( longitude => $use_long, );
        my $short_name = sprintf( "%s%02d", $use_long >= 0 ? "East" : "West", int( abs( $long / $tz_degree_width ) ) );
        my $is_utc     = ( $long == 0 ) ? 1 : 0;
        isa_ok( $tz, 'TimeZone::Solar' );
        is( $tz->longitude,               $use_long,   "longitude: $use_long" );
        is( $tz->is_floating,             0,           "should not be floating ($long)" );
        is( $tz->is_utc,                  $is_utc,     "is UTC: " . ( $is_utc ? "true" : "false" ) . " ($long)" );
        is( $tz->is_olson,                0,           "should not be based on Olson database ($long)" );
        is( $tz->category,                "Solar",     "category: Solar ($long)" );
        is( $tz->short_name_for_datetime, $short_name, "short name: $short_name ($long)" );
        is( $tz->is_dst_for_datetime($date_jan), 0,    "no DST in January ($long)" );
        is( $tz->is_dst_for_datetime($date_jul), 0,    "no DST in July ($long)" );
    }
    return;
}

# main
plan tests => 9 * $tests_per_cycle;
run_tests();
