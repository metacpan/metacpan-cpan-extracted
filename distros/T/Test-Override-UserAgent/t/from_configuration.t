#!perl -T

use lib 't/lib';

use Test::More tests => 6;
use Test::Fatal;

use LWP::UserAgent;

BEGIN {
	use_ok('MyUAConfig'); # Our configuration
	use_ok('MyUAConfigLive'); # Our configuration with live
}

# Is the configuration us?
isa_ok(MyUAConfig->configuration, 'Test::Override::UserAgent', '__PACKAGE__->configure->isa');

# Create a new user agent
my $ua = LWP::UserAgent->new;

# Install the overrides
is(exception {
	MyUAConfig->configuration->install_in_user_agent($ua);
}, undef, 'Install overrides into UA');

# Get the echo URI page
my $response = $ua->get('http://localhost/echo_uri');

# See if the response body is right
is($response->content, 'http://localhost/echo_uri', 'Echo page intercepted');

ok(MyUAConfigLive->configuration->allow_live_requests,
	'Configuration with allow live on');

exit 0;
