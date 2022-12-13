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
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

use utf8;
use Carp;
use Test::More;
use Test::Exception;
use Readonly;
use TimeZone::Solar;

# constants
Readonly::Scalar my $total_tests => 3 + 4 + 8 + 1;

# perform tests
sub run_tests
{
    # class method calls from unsupported class => 6 tests
    my $uni_obj = bless {}, "UNIVERSAL";
    dies_ok { TimeZone::Solar::version(); } "undefined class in version()";
    dies_ok { TimeZone::Solar::version("UNIVERSAL"); } "invalid class access to version() - name";
    dies_ok { TimeZone::Solar::version($uni_obj); } "invalid class access to version() - ref";

    # feed bad parameters to _tz_instance() => 4 tests
    dies_ok { TimeZone::Solar::_tz_instance() } "_tz_instance() croaks on undef hashref";
    dies_ok { TimeZone::Solar::_tz_instance(0) } "_tz_instance() croaks on non-hash value for hashref";
    my %bad_params;
    dies_ok { TimeZone::Solar::_tz_instance( \%bad_params ) } "_tz_instance() croaks on missing short_name";
    $bad_params{short_name} = "Invalid001";
    dies_ok { TimeZone::Solar::_tz_instance( \%bad_params ) } "_tz_instance() croaks on misformatted short_name";

    # instantiation tests => 8 tests
    dies_ok { my $tz = TimeZone::Solar::new("UNIVERSAL"); } "invalid class to new()";
    dies_ok { my $tz = TimeZone::Solar->new(); } "Longitude is mandatory";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => 'zero' ); } "Longitude must be numeric";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => 0, latitude => 'zero' ); } "Latitude must be numeric";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => 181 ); } "Longitude must be <=  180";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => -181 ); } "Longitude must be >= -180";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => 0, latitude => 91 ); } "Latitude must be <=  90";
    dies_ok { my $tz = TimeZone::Solar->new( longitude => 0, latitude => -91 ); } "Latitude must be >= -90";

    # force unlikely failures => 1 test
    dies_ok { _tz_subclass( "TimeZone::Solar::Flare", test_break_eval => 1 ) } "_tz_subclass force fail";
}

# main
plan tests => $total_tests;
run_tests();
