#!/usr/bin/perl -wT

use strict;
use Win32::Girder::IEvent::Server;

my $gs = Win32::Girder::IEvent::Server->new( LocalPort => 1024 )
	|| die "New failed";

## Following line coming soon
#$gs->allow("workpc"); # Allow this machine to connect

while (my $event = $gs->wait_for_event(60)) {
	if (defined($event)) {
		print "Got event [$event]\n";
	} else {
		print "Heartbeat\n";
	}	
}
