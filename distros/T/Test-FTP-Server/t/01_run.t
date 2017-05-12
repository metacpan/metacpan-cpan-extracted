#!perl
##!perl -T

use strict;
use warnings;

use Test::More;

use Test::FTP::Server;
use Test::TCP;

use Net::FTP;

my $user = 'testid';
my $pass = 'testpass';

test_tcp(
	server => sub {
		my $port = shift;

		my $server = Test::FTP::Server->new(
			'users' => [{
				'user' => $user,
				'pass' => $pass,
				'root' => '/',
			}],
			'ftpd_conf' => {
				'port' => $port,
				'daemon mode' => 1,
				'run in background' => 0,
			},
		);
		ok($server, 'init server');

		$server->run;
	},
	client => sub {
		my $port = shift;

		my $ftp = Net::FTP->new('localhost', Port => $port);
		ok($ftp);
		ok($ftp->login($user, $pass));
		ok($ftp->quit());
	},
);

done_testing;

1;
