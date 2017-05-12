#!/usr/bin/perl

use Test::More tests => 14;
use Carp;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelper;
use_ok( 'Weather::Bug::DateParser' );

isa_ok( Weather::Bug::DateParser->new(), 'Weather::Bug::DateParser' );

parse_ok( '3/25/2009 5:57:38 PM', { ymd=>'2009-03-25', hms=>'17:57:38' } );
parse_ok( '3/25/2009 5:57:38 AM', { ymd=>'2009-03-25', hms=>'05:57:38' } );
parse_ok( '12/25/2009 5:57:38 PM', { ymd=>'2009-12-25', hms=>'17:57:38' } );
parse_ok( '12/25/2009 5:57:38 AM', { ymd=>'2009-12-25', hms=>'05:57:38' } );
parse_ok( '10/5/2009 5:57:38 PM', { ymd=>'2009-10-05', hms=>'17:57:38' } );
parse_ok( '10/5/2009 5:57:38 AM', { ymd=>'2009-10-05', hms=>'05:57:38' } );

parse_ok( '25-March-2009 01:12:00 AM', { ymd=>'2009-03-25', hms=>'01:12:00' } );
parse_ok( '25-March-2009 01:12:00 PM', { ymd=>'2009-03-25', hms=>'13:12:00' } );
parse_ok( '5-March-2009 01:12:00 AM', { ymd=>'2009-03-05', hms=>'01:12:00' } );
parse_ok( '5-March-2009 01:12:00 PM', { ymd=>'2009-03-05', hms=>'13:12:00' } );
parse_ok( '01-May-2009 01:12:00 AM', { ymd=>'2009-05-01', hms=>'01:12:00' } );
parse_ok( '01-May-2009 01:12:00 PM', { ymd=>'2009-05-01', hms=>'13:12:00' } );

sub parse_ok
{
    my ($str, $desc) = @_;
    my $p = Weather::Bug::DateParser->new();
    my $d = $p->parse_datetime( $str );
    datetime_ok( $d, $str, $desc );
}
