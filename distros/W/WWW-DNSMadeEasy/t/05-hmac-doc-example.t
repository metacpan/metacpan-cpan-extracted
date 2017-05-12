#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use WWW::DNSMadeEasy;

BEGIN {

	my $dme = WWW::DNSMadeEasy->new({
		api_key => '1c1a3c91-4770-4ce7-96f4-54c0eb0e457a',
		secret => 'c9b5625f-9834-4ff8-baba-4ed5f32cae55',
	});

	isa_ok($dme,'WWW::DNSMadeEasy');
	
	my $headers = $dme->get_request_headers(DateTime->new({
		year => 2011,
		month => 2,
		day => 12,
		hour => 20,
		minute => 59,
		second => 04,
		time_zone => 'GMT',
	}));
	
	is_deeply($headers,{
		'x-dnsme-apiKey' => '1c1a3c91-4770-4ce7-96f4-54c0eb0e457a',
		'x-dnsme-hmac' => 'b3502e6116a324f3cf4a8ed693d78bcee8d8fe3c',
		'x-dnsme-requestDate' => 'Sat, 12 Feb 2011 20:59:04 GMT',
	},'request headers generated like in documentation example');
	
}

done_testing;
