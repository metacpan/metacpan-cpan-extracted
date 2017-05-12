use Test::More  tests => 21;
use DateTime;

# Use
BEGIN { 
	use_ok('WebService::OCTranspo');
}

# Methods available
can_ok('WebService::OCTranspo', qw( new schedule_for_stop ));

my $oc = WebService::OCTranspo->new();
isa_ok( $oc, 'WebService::OCTranspo');

# No args, dies
eval { $oc->schedule_for_stop() };
like($@, qr/stop_id argument required for schedule_for_stop\(\)/, 'dies if no args given' );

# missing date, dies
eval { $oc->schedule_for_stop({ stop_id => '9999', route_id => '9999'}) };
like($@, qr/date argument required for schedule_for_stop\(\)/, 'dies if date missing' );

## Following tests require network connectivity

# A nice predictible date:
# 1178942018 is Fri May 11 23:53:38 2007
my $now = DateTime->from_epoch( epoch => 1178942018, time_zone => 'America/New_York' )->truncate( to =>'day');

# Bogus stop number
eval { $oc->schedule_for_stop({ stop_id => '9999', route_id => '9999', date => $now }) };
like( $@, qr/Stop 9999 does not seem to exist/, 'dies if invalid stop ID given');

# Bogus route number for valid stop
eval { $oc->schedule_for_stop({ stop_id => '6103', route_id => '9999', date => $now }) };
like( $@, qr/Route 9999 does not service that stop/, 'dies if invalid route ID given');

# Valid route, single-route stop
my $s;
eval { $s = $oc->schedule_for_stop({ stop_id => 4487, route_id => 176, date => $now}) };
is( $@, '', 'Got a schedule');
is( $s->{stop_number}, 4487, '... for correct stop number');
is( $s->{route_number}, 176, '... and for correct route number');
is( $s->{date}->ymd, '2007-05-11', '... and for correct day');

is( $s->{stop_name}, 'MERIVALE / AD. 1460', '... and with expected stop name');
is( $s->{route_name}, 'Nepean South / sud', '... and with expected route name');

is( scalar @{ $s->{'times'} }, 54, '54 trips leave for that route from this stop');
is_deeply( $s->{notes}, { 
	'D' => 'Destination NEPEAN C.   MERIVALE   SLACK',
}, 'Got one note for this stop');

# Fetch second stop and route
undef $s;
eval { $s = $oc->schedule_for_stop({ stop_id => 4484, route_id => 118, date => $now}) };
is( $@, '', 'Got a schedule');
is( $s->{stop_number}, 4484, '... for correct stop number');
is( $s->{route_number}, 118, '... and for correct route number');
is( $s->{date}->ymd, '2007-05-11', '... and for correct day');

is( $s->{stop_name}, 'BASELINE /  LAURENTIAN H.S.', '... and with expected stop name');
is( $s->{route_name}, 'Kanata', '... and with expected route name');
