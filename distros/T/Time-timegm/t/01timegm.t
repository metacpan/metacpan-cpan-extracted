#!/usr/bin/perl -w

use strict;

use Test::More tests => 12;

use Time::timegm qw( timegm );

# Some well-founded times that ought to come out correctly

is( timegm( 0,0,0,1,0,70 ), 0,            "timegm 1970-01-01T00:00:00" );
is( timegm( 1,0,0,1,0,70 ), 1,            "timegm 1970-01-01T00:00:01" );
is( timegm( 0,1,0,1,0,70 ), 60,           "timegm 1970-01-01T00:01:00" );
is( timegm( 0,0,1,1,0,70 ), 60*60,        "timegm 1970-01-01T01:00:00" );
is( timegm( 0,0,0,2,0,70 ), 60*60*24,     "timegm 1970-01-02T00:00:00" );
is( timegm( 0,0,0,1,1,70 ), 60*60*24*31,  "timegm 1970-02-01T00:00:00" );
is( timegm( 0,0,0,1,0,71 ), 60*60*24*365, "timegm 1971-02-01T00:00:00" );

is( timegm(  0, 0,0,1,0,100 ),  946684800, "timegm 2000-01-01T00:00:00" );
is( timegm( 40,46,1,9,8,101 ), 1000000000, "timegm 2000-01-01T00:00:00" );

# 32nd Jan == 1st Feb
is( timegm( 0,0,0,32,0,100 ), timegm( 0,0,0,1,1,100 ), "timegm 2000-02-01T00:00:00" );

# 32nd Dec 2000 == 1st Jan 2001
is( timegm( 0,0,0,32,11,100 ), timegm( 0,0,0,1,0,101 ), "timegm 2001-01-01T00:00:00" );

my $now = time;
is( timegm( gmtime $now ), $now, 'gmtime->timegm roundtrip now' );
