#!/usr/bin/env perl

use Data::Dumper;
use Test::More tests => 90;

use lib 'lib/';

use constant {
	HTTP_PROXY => 'http',
	SOCKS4_PROXY => 'socks4',
	SOCKS5_PROXY => 'socks',
	HTTPS_PROXY => 'https',
};

use_ok('WebService::Gyazo');

my $ua = WebService::Gyazo->new();
can_ok($ua, 'setProxy');

my @protocols_ok = (HTTP_PROXY, HTTPS_PROXY, SOCKS4_PROXY, SOCKS5_PROXY);
my @ips_ok = qw( 127.0.0.1 11.111.11.111 );
my @ports_ok = qw( 80 8080 100 200 65535 );

for my $protocol (@protocols_ok) {
	for my $ip (@ips_ok) {
		for my $ports (@ports_ok) {
			my $proxy = $protocol.'://'.$ip.':'.$ports;
			is($ua->setProxy($proxy), 1, '$ua->setProxy("'.$proxy.'") == 1 - '.$ua->error);
		}
	}
}

my @protocols_err = qw( www sts sas http );
my @ips_err = qw( 127.0.500.1 1111.111.11.5 1.1.1.1.1  127.0.0.1 );
my @ports_err = qw( 65536 999999999 9929292929 );

for my $protocol (@protocols_err) {
	for my $ip (@ips_err) {
		for my $ports (@ports_err) {
			my $proxy = $protocol.'://'.$ip.':'.$ports;
			is($ua->setProxy($proxy), 0, '$ua->setProxy("'.$proxy.'") == 0 - '.$ua->error);
		}
	}
}