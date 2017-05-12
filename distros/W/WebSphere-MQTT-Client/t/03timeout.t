# Check that the retry_interval / retry_count is handled correctly

use strict;
use Test;
use Time::HiRes qw(gettimeofday tv_interval);
use WebSphere::MQTT::Client;

BEGIN { plan tests => 2 }

my $mqtt = WebSphere::MQTT::Client->new(
	Hostname => 'localhost',
	Port => 59999,
	retry_interval => 5,
	retry_count => 3,
	# NOTE: we must run with clean_start=0. When clean_start=1
	# (the default), the C API will *not* automatically reconnect.
	# This is because clean_start wipes all subscriptions, and the
	# API doesn't know what subscriptions the applications wants.
	clean_start => 0,
);

my $t0 = [gettimeofday];
my $rc = $mqtt->connect();
ok( $rc eq 'FAILED' );
my $interval = tv_interval($t0);
#print STDERR "interval = $interval\n";

# 3 retries = 4 tries
# each is followed by a 5 second interval
ok( $interval > 19.0 && $interval < 21.0 );
