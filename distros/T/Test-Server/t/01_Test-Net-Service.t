#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 3;

use Test::Differences;
use Test::Exception;
use English '-no_match_vars';

BEGIN {
	use_ok('Test::Net::Service') or exit;
}


exit main();

sub main {
	my $net_service = Test::Net::Service->new(
		'host'  => 'camel.cle.sk',
		'proto' => 'tcp',
	);
	
	my $ret;
	lives_ok(
		sub {
			$ret = $net_service->test(
				'socket'  => 1,
				'port'    => 22,
				'proto'   => 'udp',
				'service' => 'dummy',
			);
		},
		'test dummy service'
	);
	
	is_deeply(
		$ret,
		{
			'host'    => 'camel.cle.sk',
			'proto'   => 'udp',
			'port'    => 22,
			'socket'  => 1,
			'service' => 'dummy',
		},
		'check args joining'
	);

	return 0
}
