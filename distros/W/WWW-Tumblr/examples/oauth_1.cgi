#!/usr/bin/env perl -w

use strict;
use 5.014;
use lib '../lib/';

use Storable;
use WWW::Tumblr::Authentication::OAuth;

my $tumblr_oauth = WWW::Tumblr::Authentication::OAuth->new(
	consumer_key => 'xxx',
	secret_key => 'xxx',
	callback => 'http://localhost/callback',
);

say $tumblr_oauth->authorize_url();

#	Save session
say "Session saved";
store $tumblr_oauth->session_store, 'tmp_session';

print "Enter oauth token: ";
chomp( my $oauth_token = <STDIN> );

print "Enter oauth verifier: ";
chomp( my $oauth_verifier = <STDIN> );

say "Restore session";
$tumblr_oauth->session_store( retrieve('tmp_session') );

$tumblr_oauth->oauth_token( $oauth_token );
$tumblr_oauth->oauth_verifier( $oauth_verifier );

say $tumblr_oauth->token();
say $tumblr_oauth->token_secret();