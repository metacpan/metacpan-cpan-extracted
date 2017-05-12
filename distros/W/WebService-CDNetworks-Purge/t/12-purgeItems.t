#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use Test::LWP::UserAgent;

use WebService::CDNetworks::Purge;

subtest 'Preconditions' => sub {

	my $useragent = Test::LWP::UserAgent -> new();
	my $service = WebService::CDNetworks::Purge -> new(
		'username' => 'xxxxxxxx',
		'password' => 'yyyyyyyy',
		'ua'       => $useragent,
	);

	throws_ok {
		$service -> purgeItems(undef, ['/a.html', '/images/b.png']);
	} qr/No pad given/, 'pad not defined';

	throws_ok {
		$service -> purgeItems('', ['/a.html', '/images/b.png']);
	} qr/No pad given/, 'pad not defined';

	throws_ok {
		$service -> purgeItems('test.example.com');
	} qr/Invalid paths given/, 'Invalid paths given';

	throws_ok {
		$service -> purgeItems('test.example.com', '/a.html');
	} qr/Invalid paths given/, 'Invalid paths given';

	lives_ok {
		local $SIG{__WARN__} = sub { like($_[0], qr/Zero paths given/, 'Carp ok'); };
		is($service -> purgeItems('test.example.com', []), undef);
	} 'Zero paths given';

	done_testing();

};

subtest 'Not found' => sub {

	my $useragent = Test::LWP::UserAgent -> new();
	my $service = WebService::CDNetworks::Purge -> new(
		'username' => 'xxxxxxxx',
		'password' => 'yyyyyyyy',
		'ua'       => $useragent,
	);

	throws_ok {
		my $purgeStatus = $service -> purgeItems('test.example.com', ['/a.html', '/images/b.png']);
	} qr/404 Not Found/, 'URL not found';

};

subtest 'result code not 200' => sub {

	my $useragent = Test::LWP::UserAgent -> new();
	$useragent -> map_response(
		qr{https://openapi.us.cdnetworks.com/purge/rest/doPurge},
		HTTP::Response -> new('200', 'OK', ['Content-Type' => 'text/plain;charset=UTF-8'], '{
		"pid": -1,
		"details": "Internal server error",
		"paths": [],
		"resultCode": 500
	}')
	);

	my $service = WebService::CDNetworks::Purge -> new(
		'username' => 'xxxxxxxx',
		'password' => 'yyyyyyyy',
		'ua'       => $useragent,
	);

	my $expected = [{
		'details' => 'Internal server error',
		'paths'   => [],
		'pid'        => -1,
		'resultCode' => 500,
	}];

	my $purgeStatus;
	lives_ok {
		$purgeStatus = $service -> purgeItems('test.example.com', ['/a.html', '/images/b.png']);
	} 'Service status not 200';

	is_deeply($purgeStatus, $expected, 'purgeItems returned the result');

};

subtest 'Happy path' => sub {

	my $useragent = Test::LWP::UserAgent -> new();
	$useragent -> map_response(
		qr{https://openapi.us.cdnetworks.com/purge/rest/doPurge},
		HTTP::Response -> new('200', 'OK', ['Content-Type' => 'text/plain;charset=UTF-8'], '{
  "details": "item rest flush (2 items)",
  "notice": "",
  "paths": [
    "/a.html",
    "/images/b.png"
  ],
  "pid": 666,
  "resultCode": 200
}')
	);

	my $service = WebService::CDNetworks::Purge -> new(
		'username' => 'xxxxxxxx',
		'password' => 'yyyyyyyy',
		'ua'       => $useragent,
	);

	my $expected = [{
		'details' => 'item rest flush (2 items)',
		'notice'  => '',
		'paths'   => [
			'/a.html',
			'/images/b.png'
		],
		'pid'        => 666,
		'resultCode' => 200,
	}];

	my $purgeStatus = $service -> purgeItems('test.example.com', ['/a.html', '/images/b.png']);
	is_deeply($purgeStatus, $expected, 'purgeItems returned the right id');

	done_testing();

};

subtest 'Happy path' => sub {

	my $useragent = Test::LWP::UserAgent -> new();
	$useragent -> map_response(
		sub {
			my $request = shift;
			return 1 if ($request -> content =~ /path=%2Fa\.html/);
		},
		HTTP::Response -> new('200', 'OK', ['Content-Type' => 'text/plain;charset=UTF-8'], '{
  "details": "item rest flush (1 items)",
  "notice": "",
  "paths": [
    "/a.html"
  ],
  "pid": 1,
  "resultCode": 200
}')
	);
	$useragent -> map_response(
		sub {
			my $request = shift;
			return 1 if ($request -> content =~ /path=%2Fimages%2Fb\.png/);
		},
		HTTP::Response -> new('200', 'OK', ['Content-Type' => 'text/plain;charset=UTF-8'], '{
  "details": "item rest flush (1 items)",
  "notice": "",
  "paths": [
    "/images/b.png"
  ],
  "pid": 2,
  "resultCode": 200
}')
	);

	my $service = WebService::CDNetworks::Purge -> new(
		'username' => 'xxxxxxxx',
		'password' => 'yyyyyyyy',
		'ua'       => $useragent,
	);

	my $expected = [
		{
			'details' => 'item rest flush (1 items)',
			'notice' => '',
			'paths' => [
				'/a.html'
			],
			'pid' => 1,
			'resultCode' => 200,
		},
		{
			'details' => 'item rest flush (1 items)',
			'notice' => '',
			'paths' => [
				'/images/b.png'
			],
			'pid' => 2,
			'resultCode' => 200,
		}
	];

	$service -> pathsPerCall(1);
	my $purgeStatus = $service -> purgeItems('test.example.com', ['/a.html', '/images/b.png']);
	is_deeply($purgeStatus, $expected, 'purgeItems returned the right result');

	done_testing();

};

## TODO: Some paths are not valid

## TODO: Auth failure

## TODO: Rate limit reached

