#!perl -T

use Test::More tests => 4;
use Test::Fatal;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

# Make a new override
my $conf = new_ok 'Test::Override::UserAgent';

# Set a simple request to be handled
is(exception {
	$conf->override_request(
		host => 'localhost',
		path => '/echo_uri',
		sub { return [200, ['Content-Type' => 'text/plain'], [shift->uri]]; },
	);
}, undef, 'Create an override for http://localhost/echo_uri');

# Create a new user agent
my $ua = LWP::UserAgent->new;

# Install the overrides
is(exception {
	$conf->install_in_user_agent($ua);
}, undef, 'Install overrides into UA');

# Get the echo URI page
my $response = $ua->get('http://localhost/echo_uri');

# See if the response body is right
is($response->content, 'http://localhost/echo_uri', 'Echo page intercepted');

exit 0;
