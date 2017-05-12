#!perl -T

use Test::More tests => 9;
use Test::Fatal;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

# Make a new override
my $conf = Test::Override::UserAgent->new->override_request(
	host => 'localhost',
	path => '/NOTHING',
	sub { return [200, ['Content-Type' => 'text/plain'], ['NO']]; },
);

# Make a user agent
my $ua = LWP::UserAgent->new(timeout => 1);

# Add a handler that does not belong to the conf
my $pre_handler_ran = 0;
$ua->add_handler(request_prepare => sub { $pre_handler_ran++; return; });

# Install
is(exception { $conf->install_in_user_agent($ua) }, undef,
	'Install into user agent');

# Make request
is($ua->get('http://localhost/NOTHING')->content, 'NO',
	'Overridden request handled');

# Test custom run count
is($pre_handler_ran, 1, 'Custom handler present after install');

# Uninstall
is(exception { $conf->uninstall_from_user_agent($ua) }, undef,
	'Uninstall from user agent');

# Make request
isnt($ua->get('http://localhost/NOTHING')->content, 'NO',
	'Overridden request no longer present');

# Test custom run count
# Count may be bigger if localhost request got a redirect
cmp_ok($pre_handler_ran, '>=', 2, 'Custom handler present after uninstall');

# Install in a clone
my $clone_ua = $conf->install_in_user_agent($ua, clone => 1);

# They should not be the same
isnt($clone_ua, $ua, 'Clone UA is clone');

# Test overrides
isnt($ua->get('http://localhost/NOTHING')->content, 'NO',
	'Original UA does not have overrides');
is($clone_ua->get('http://localhost/NOTHING')->content, 'NO',
	'Clone UA has overrides');

exit 0;
