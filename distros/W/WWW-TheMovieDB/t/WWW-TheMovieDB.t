#########################

use strict;
use warnings;

use Test::Simple tests => 6;
use WWW::TheMovieDB;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# My personal API key, don't use this in your app, get your own.
# https://www.themoviedb.org/account/signup
my $api_key = "c3df732a39ff82b47035cda9078a7a24";

my $api = new WWW::TheMovieDB({
	'key' => $api_key
});

ok( defined($api) && ref $api   eq 'WWW::TheMovieDB',  'new() works'         );

ok( ref $api->api_key($api_key) eq 'WWW::TheMovieDB',  'api_key() works'     );
ok( ref $api->type('json')      eq 'WWW::TheMovieDB',  'type() works'        );
ok( ref $api->language('en')    eq 'WWW::TheMovieDB',  'language() works'    );
ok( ref $api->version('3')      eq 'WWW::TheMovieDB',  'version() works'     );
# Skipping
#$api->request_token
#$api->session_id
#$api->guest_session_id
#$api->user_id

# Configuration
ok( ($api->Configuration::configuration() =~ m/Invalid API key/) == 0, 'Configuration::configuration() works' );

