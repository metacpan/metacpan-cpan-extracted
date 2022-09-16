#!/usr/bin/env perl
# t/013-datetime.t - unit tests for date & time stamps in WebFetch
use strict;
use warnings;
use utf8;
use autodie;
use Readonly;

use Test::More;
use Test::Exception;
use WebFetch;
use WebFetch::Input::SiteNews;

# configuration & constants
Readonly::Array my @tests => (
    {
        # date only, no time zone/locale
        tz      => [''],
        timestr => "2022-08-05",
        check   => {
            year      => 2022,
            month     => 8,
            day       => 5,
            hour      => undef,
            minute    => undef,
            second    => undef,
            time_zone => undef,
            anchor    => "2022-08-05"
        },
    },
    {
        # date only, multiple time zones
        tz      => [qw(PST8PDT US/Pacific America/Los_Angeles)],
        locale  => "en-US",
        timestr => "2022-08-05",
        check   => {
            year      => 2022,
            month     => 8,
            day       => 5,
            hour      => undef,
            minute    => undef,
            second    => undef,
            time_zone => undef,
            anchor    => "2022-08-05"
        },
    },
    {
        # full date/time, no time zone/locale
        tz      => [''],
        timestr => "2022-08-05T19:30:00",
        check   => {
            year      => 2022,
            month     => 8,
            day       => 5,
            hour      => 19,
            minute    => 30,
            second    => 0,
            time_zone => "floating",
            anchor    => "2022-08-05-19-30-00"
        },
    },
    {
        # full date/time, multiple time zones (west) from floating time
        tz      => [qw(PST8PDT US/Pacific America/Los_Angeles)],
        locale  => "en-US",
        timestr => "2022-08-05T19:30:00",
        check   => {
            year      => 2022,
            month     => 8,
            day       => 5,
            hour      => 19,
            minute    => 30,
            second    => 0,
            time_zone => "floating",
            anchor    => "2022-08-05-19-30-00"
        },
    },
    {
        # full date/time, multiple time zones (west) from UTC
        tz      => [qw(PST8PDT US/Pacific America/Los_Angeles)],
        locale  => "en-US",
        timestr => "2022-08-05T19:30:00+00:00",
        check   => {
            year      => 2022,
            month     => 8,
            day       => 5,
            hour      => 19,
            minute    => 30,
            second    => 0,
            time_zone => "UTC",
            anchor    => "2022-08-05-19-30-00"
        },
    },
    {
        # full date/time, one time zone (east) from floating time
        tz      => [qw(Australia/Sydney)],
        locale  => "en-AU",
        timestr => "2022-08-05T19:30:00",
        check   => {
            year      => 2022,
            month     => 8,
            day       => 5,
            hour      => 19,
            minute    => 30,
            second    => 0,
            time_zone => "floating",
            anchor    => "2022-08-05-19-30-00"
        },
    },
    {
        # full date/time, one time zone (east) from UTC
        tz      => [qw(Australia/Sydney)],
        locale  => "en-AU",
        timestr => "2022-08-05T19:30:00+00:00",
        check   => {
            year      => 2022,
            month     => 8,
            day       => 5,
            hour      => 19,
            minute    => 30,
            second    => 0,
            time_zone => "UTC",
            anchor    => "2022-08-05-19-30-00"
        },
    },
);

# count tests from data
sub count_tests
{
    my $count = 0;
    foreach my $rec (@tests) {
        $count += int( @{ $rec->{tz} } ) * int( keys %{ $rec->{check} } );
    }
    return $count;
}

# extract data by field
sub extract
{
    my ( $timeref, $field, $opt_ref ) = @_;
    if ( ref $timeref ) {
        if ( $field eq "anchor" ) {
            return WebFetch::anchor_timestr( $opt_ref, $timeref );
        }
        if ( ref $timeref eq "ARRAY" ) {
            my %data = @$timeref;
            if ( exists $data{$field} ) {
                return $data{$field};
            }
            return;
        }
        if ( $timeref->isa("DateTime") ) {
            return $timeref->$field();
        }
    } else {
        return "not a reference";
    }
}

# test functions
sub test_year   { my $timeref = shift; return extract( $timeref, "year",   {} ); }
sub test_month  { my $timeref = shift; return extract( $timeref, "month",  {} ); }
sub test_day    { my $timeref = shift; return extract( $timeref, "day",    {} ); }
sub test_hour   { my $timeref = shift; return extract( $timeref, "hour",   {} ); }
sub test_minute { my $timeref = shift; return extract( $timeref, "minute", {} ); }
sub test_second { my $timeref = shift; return extract( $timeref, "second", {} ); }
sub test_anchor { my $timeref = shift; return extract( $timeref, "anchor", {} ); }

sub test_time_zone
{
    my $timeref   = shift;
    my $extracted = extract( $timeref, "time_zone", {} );
    if ( ref $extracted ) {
        if ( $extracted->isa("DateTime::TimeZone") ) {
            return $extracted->name();
        }
    }
    return $extracted;
}

#
# main
#

plan tests => count_tests();
foreach my $rec (@tests) {
    foreach my $tz ( @{ $rec->{tz} } ) {
        my %dt_opt;
        if ( defined $tz and length($tz) > 0 ) {
            $dt_opt{time_zone} = $tz;
        }
        if ( exists $rec->{locale} ) {
            $dt_opt{locale} = $rec->{locale};
        }
        my $time_ref = WebFetch::parse_date( $rec->{timestr} );
        foreach my $check ( sort keys %{ $rec->{check} } ) {
            my $test_func = "test_$check";
            if ( main->can($test_func) ) {
                my $test_name = $rec->{timestr};
                if ( defined $tz and length($tz) > 0 ) {
                    $test_name .= " tz='$tz'";
                }
                if ( exists $rec->{locale} ) {
                    $test_name .= " locale='$rec->{locale}'";
                }
                $test_name .= " $check";
                ## no critic (TestingAndDebugging::ProhibitNoStrict)
                no strict 'refs';
                is( &$test_func($time_ref), $rec->{check}{$check}, $test_name );
            }
        }
    }
}
