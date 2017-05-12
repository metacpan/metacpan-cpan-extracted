#!/usr/bin/env perl -w

use utf8;
use strict;
use lib::abs '../lib';

use XML::RPC::Fast;
use Data::Dumper;

my $rpc = XML::RPC::Fast->new(
	'http://betty.userland.com/RPC2',
	ua        => 'AnyEventSync',
	useragent => 'Test/0.1',
	timeout   => 1,
);

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
	},
);

warn "First request finished\n";

my @result;
eval {
	@result = $rpc->call(
		'examples.getStateStruct',
		{ state1 => 12, state2 => 28 }
	);
};

if (@result) {
	print "Success: ".Dumper \@result;
} else {
	warn "Failed: $XML::RPC::Fast::faultCode: $@";
}
warn "Second request finished\n";
