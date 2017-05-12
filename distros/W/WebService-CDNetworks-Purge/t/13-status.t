#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Test::LWP::UserAgent;

use WebService::CDNetworks::Purge;

subtest 'Not found' => sub {

	my $useragent = Test::LWP::UserAgent -> new();
	my $service = WebService::CDNetworks::Purge -> new(
		'username' => 'xxxxxxxx',
		'password' => 'yyyyyyyy',
		'ua'       => $useragent,
	);

	throws_ok {
		$service -> status(666);
	} qr/404 Not Found/, 'URL not found';

};

subtest 'result code not 200' => sub {

	my $useragent = Test::LWP::UserAgent -> new();
	$useragent -> map_response(
		qr{https://openapi.us.cdnetworks.com/purge/rest/status},
		HTTP::Response -> new('200', 'OK', ['Content-Type' => 'text/plain;charset=UTF-8'], '{
		"details": "Internal server error",
		"percentComplete": 0.0,
		"resultCode": 500
	}')
	);

	my $service = WebService::CDNetworks::Purge -> new(
		'username' => 'xxxxxxxx',
		'password' => 'yyyyyyyy',
		'ua'       => $useragent,
	);

	throws_ok {
		$service -> status(666);
	} qr/Invalid .*: 500/, 'Service status not 200';

};

subtest 'Happy path' => sub {

	my $useragent = Test::LWP::UserAgent -> new();
	$useragent -> map_response(
		qr{https://openapi.us.cdnetworks.com/purge/rest/status\?.*pid=666},
		HTTP::Response -> new('200', 'OK', ['Content-Type' => 'text/plain;charset=UTF-8'], '{
		"resultCode": 200,
		"details": "success",
		"percentComplete": 100.0
	}')
	);

	my $service = WebService::CDNetworks::Purge -> new(
		'username' => 'xxxxxxxx',
		'password' => 'yyyyyyyy',
		'ua'       => $useragent,
	);

	my $status = $service -> status(666);
	my $expected = {
		'resultCode'      => 200,
		'details'         => 'success',
		'percentComplete' => 100.0,
	};

	is_deeply($status, $expected, 'status');

};

## TODO: Auth failure

## TODO: Rate limit exceeded

