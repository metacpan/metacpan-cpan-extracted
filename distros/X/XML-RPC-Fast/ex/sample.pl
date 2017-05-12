#!/usr/bin/env perl -w

use utf8;
use strict;
use lib::abs '../lib';

use XML::RPC::Fast;
use Data::Dumper;

my $rpc = XML::RPC::Fast->new(
	'http://betty.userland.com/RPC2',
	encoder   => 'LibXML',
	ua        => 'LWP',
	useragent => 'Test/0.1',
	timeout   => 1,
);

# This never croaks.
$rpc->call(
	sub {
		if (ref $_[0] eq 'HASH' and exists $_[0]{fault}) {
			warn "Failed: $_[0]{fault}{faultCode} / $XML::RPC::Fast::faultCode: $_[0]{fault}{faultString}";
		} else {
			print "Success: ".Dumper \@_;
		}
	},
	'examples.getStateStruct',
	{ state1 => 14, state2 => 25 }
);

# This croaks on error, and return result on success
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

