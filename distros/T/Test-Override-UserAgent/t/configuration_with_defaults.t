#!perl -T

use lib 't/lib';

use Test::More tests => 10;
use Test::Fatal;

use LWP::UserAgent;

BEGIN {
	use_ok('MyUAConfigDefaults'); # Our configuration with defaults
}

# Create a new user agent
my $ua = LWP::UserAgent->new;

# Install the overrides
is(exception {
	MyUAConfigDefaults->configuration->install_in_user_agent($ua);
}, undef, 'Install overrides into UA');

# Make sure the host override set
is $ua->get('http://localhost/')->content, 'override', 'Override set host';

# Check that embedded defaults worked
is $ua->get('http://localhost/only.get')->content, 'override', 'GET /only.get';
isnt $ua->post('http://localhost/only.get')->content, 'override', 'POST /only.get';

# Check that embedded defaults extended
isnt $ua->get('http://elsewhere/only.get')->content, 'override', '/only.get extended';

# Check defaults reverted
is $ua->get('http://localhost/all.methods')->content, 'override', 'GET /all.methods';
is $ua->post('http://localhost/all.methods')->content, 'override', 'POST /all.methods';

# Check that defaults can be overridden deeper in scope
is $ua->get('http://someplace/other')->content, 'override', 'host default changed';
isnt $ua->get('http://localhost/other')->content, 'override', 'old host not set';

exit 0;
