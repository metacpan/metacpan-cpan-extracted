#!/usr/bin/env perl -w

use strict;
use 5.014;
use lib '../lib/';

use Storable;
use WWW::Tumblr;

my $oauth = WWW::Tumblr->new(
	consumer_key => 'xxx',
	secret_key => 'xxx',
	callback => 'http://localhost/callback',
)->oauth_tools;

say $oauth->authorize_url();

#	Save session
say "Session saved";
store $oauth->session_store, 'tmp_session';

print "Enter oauth token: ";
chomp( my $oauth_token = <STDIN> );

print "Enter oauth verifier: ";
chomp( my $oauth_verifier = <STDIN> );

say "Restore session";
$oauth->session_store( retrieve('tmp_session') );

$oauth->oauth_token( $oauth_token );
$oauth->oauth_verifier( $oauth_verifier );

say $oauth->token();
say $oauth->token_secret();