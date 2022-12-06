#!/usr/bin/env perl
# t/001-breakage.t - breaking tests for TimeZone::Solar
# some tests adapted from DateTime::TimeZone::LMT tests
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
use TimeZone::Solar;

# constants
Readonly::Scalar my $total_tests => 10;

# perform tests
sub run_tests
{
    # class method calls from unsupported class
    dies_ok { TimeZone::Solar::version(); } "undefined class in version()";
    dies_ok { TimeZone::Solar::version("UNIVERSAL"); } "invalid class access to version()";
    dies_ok { TimeZone::Solar::_get_const(); } "undefined class in _get_const()";
    dies_ok { TimeZone::Solar::_get_const( "UNIVERSAL", "PRECISION_DIGITS" ); } "invalid class access to _get_const()";

    # instantiation tests
    dies_ok { my $tz = TimeZone::Solar->new(); } "Longitude is mandatory";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => 'zero' ); } "Longitude must be numeric";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => 181 ); } "Longitude must be <=  180";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => -181 ); } "Longitude must be >= -180";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => 0, latitude => 91 ); } "Latitude must be <=  90";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => 0, latitude => -91 ); } "Latitude must be >= -90";
}

# main
plan tests => $total_tests;
run_tests();
