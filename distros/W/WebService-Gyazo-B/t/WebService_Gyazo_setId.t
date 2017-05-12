#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 7;

use lib 'lib/';

use constant {
	HTTP_PROXY => 'http',
	SOCKS4_PROXY => 'socks4',
	SOCKS5_PROXY => 'socks',
	HTTPS_PROXY => 'https',
};

use_ok('WebService::Gyazo::B');

my $ua = WebService::Gyazo::B->new();
can_ok($ua, 'setId');

my @ids_ok = qw( 1234567 123qwe123qwe12 111 );
for my $id (@ids_ok) {
	is($ua->setId($id), 1, '$ua->setId("'.$id.'") == 1 - '.$ua->error);
}

my @ids_err = qw( 123456712345678764532 12345678ddddddd&*6 );
for my $id (@ids_err) {
	is($ua->setId($id), 0, '$ua->setId("'.$id.'") == 0 - '.$ua->error);
}
