#!/usr/bin/perl
use strict; use warnings;

use Test::More tests=>10;
use lib 'lib';

use_ok( 'WWW::Instapaper::Client');
require_ok( 'WWW::Instapaper::Client');

for (qw(agent_string api_url http_proxy http_proxyuser http_proxypass username password)) {
	eval { my $obj = WWW::Instapaper::Client->new( $_ => 'test-value' ) };
	ok( ! $@, "$_ is a valid parameter" );
}

eval { my $obj = WWW::Instapaper::Client->new( 'INVALID' => 'test-value' ) };
ok( $@, 'dies with invalid parameter' );
