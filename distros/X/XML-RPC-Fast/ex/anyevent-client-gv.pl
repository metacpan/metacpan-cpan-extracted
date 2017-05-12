#!/usr/bin/env perl -w

use utf8;
use strict;
use lib::abs '../lib';

use AnyEvent;
use XML::RPC::Fast;
use Data::Dumper;

my $rpc = XML::RPC::Fast->new(
	'http://betty.userland.com/RPC2',
	ua        => 'AnyEvent',
	useragent => 'Test/0.1',
	timeout   => 1,
);

my $cv = AnyEvent->condvar;
$cv->begin(sub {$cv->send}); # Use group callback

# Now, make any number of calls. When ged enough, call $cv->send;

for (1..2) {
	$cv->begin;
	$rpc->call(
		sub {
			if (ref $_[0] eq 'HASH' and exists $_[0]{fault}) {
				warn "Failed: $_[0]{fault}{faultCode} / $XML::RPC::Fast::faultCode: $_[0]{fault}{faultString}";
			} else {
				print "Success: ".Dumper \@_;
			}
			$cv->end;
		},
		'examples.getStateStruct',
		{ state1 => 14, state2 => 25 }
	);
}

$cv->end;
$cv->recv; # This blocks until $cv->send

