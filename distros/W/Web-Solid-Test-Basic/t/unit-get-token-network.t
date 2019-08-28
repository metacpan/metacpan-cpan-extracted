#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;
use Web::Solid::Test::HTTPLists;

use URI;
use FindBin qw($Bin);
use URI;
use LWP::UserAgent;
use IO::Socket::SSL;

my $request_url = URI->new('http://example.test');
my $all_tokens_url = 'https://idp.test.solidproject.org/tokens';

BEGIN { # TODO: Weird way to set it
  $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';
}

my $ua = LWP::UserAgent->new(verify_hostname => 1);
my $test_if_fake_idp_is_up_request = $ua->get($all_tokens_url);

 SKIP: {
      skip "Unsuccessful response from $all_tokens_url : " .$test_if_fake_idp_is_up_request->content , 1 unless ($test_if_fake_idp_is_up_request->is_success);

		my $bearer = Web::Solid::Test::HTTPLists::_create_authorization_field(URI->new($all_tokens_url . '/BOB_POP_FOR_BAD_APP_GOOD'), $request_url);
		note('Bearer token starts with ' . substr($bearer, 7, 21) . ' ... ') ;
		like($bearer, qr/Bearer \S{20,}/, 'Bearer token returned from test IDP');
	 }

done_testing;
