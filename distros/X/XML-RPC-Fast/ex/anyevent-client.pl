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

# Now, make any number of calls. When ged enough, call $cv->send;
my $n = 2;
my $got = 0;

$rpc->req(
	call => [ 'examples.getStateStruct' => { state1 => 14, state2 => 25 } ],
	cb => sub {
		if (ref $_[0] eq 'HASH' and exists $_[0]{fault}) {
			warn "Failed: $_[0]{fault}{faultCode} / $XML::RPC::Fast::faultCode: $_[0]{fault}{faultString}";
		} else {
			print "Success: ".Dumper \@_;
		}
		$cv->send if ++$got == $n;
	},
) for 1..$n;

# This blocks until $cv->send
$cv->recv;
