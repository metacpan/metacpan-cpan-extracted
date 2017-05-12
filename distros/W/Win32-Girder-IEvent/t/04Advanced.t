use strict;
use Test;

my $pass = 'TestEnv';
my $port = 1024;
my $event = '42';

BEGIN { plan tests => 5 };

use Win32::Girder::IEvent::Client;
use Win32::Girder::IEvent::Server;

ok(1); # If we made it this far, we're ok.

my $gs = Win32::Girder::IEvent::Server->new(
	LocalPort => 1024,
	PassWord  => $pass,
	Reuse => 1,
);

ok($gs);

if (defined(my $pid = fork)) {
	if ($pid) {
		# parent;
		my $in_event = $gs->wait_for_event();
		wait();
		# Skip two tests (in other process)
		$Test::ntest+=2; # <-- is this naughty?
		ok($in_event, $event);

	} else {

		# child
		sleep 1;
		my $gc = Win32::Girder::IEvent::Client->new(
			PeerHost => 'localhost',
			PeerPort => $port,
			PassWord => $pass,
		);
		ok($gc);
		ok($gc->send($event));

		$gc->close;
		exit(0);
		
	}
} else {
	die "Can't fork - [$!]. This is more of a system problem than a module one."
}

