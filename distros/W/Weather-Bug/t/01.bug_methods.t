use Test::More tests => 2;

use warnings;
use strict;

use Weather::Bug;

my $wxbug = Weather::Bug->new( -key => 'FAKELICENSEKEY' );

isa_ok( $wxbug, 'Weather::Bug' );
can_ok( $wxbug, qw/list_stations request get_forecast get_alerts
                   get_live_compact_weather get_live_weather/ );

