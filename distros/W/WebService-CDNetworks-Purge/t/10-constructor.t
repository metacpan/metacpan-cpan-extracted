#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Test::LWP::UserAgent;

use WebService::CDNetworks::Purge;

subtest 'Invalid contructor parameters' => sub {

	throws_ok {
		my $service = WebService::CDNetworks::Purge -> new({});
	} qr/Attribute \(\w+\) is required at constructor/, 'constructor called without credentials';

};

subtest 'Valid contructor parameters' => sub {

	my $useragent = Test::LWP::UserAgent -> new();
	my $service;

	lives_ok {
		$service = WebService::CDNetworks::Purge -> new(
			'username' => 'xxxxxxxx',
			'password' => 'yyyyyyyy',
			'ua'       => $useragent,
		);
	} 'Contructor expecting to live';

	isa_ok($service, 'WebService::CDNetworks::Purge');

};

