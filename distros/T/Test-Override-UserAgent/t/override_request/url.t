#!perl -T

use Test::More 0.88 tests => 3;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

# Make a new override
my $conf = Test::Override::UserAgent->new;

# Generate a random number to add as a token
my $token = rand();

# Create a new user agent
my $ua = LWP::UserAgent->new(timeout => 2);

# Subroutine to check the page result
my $check_page = sub {
	my ($url, $body, $message) = @_;

	# Request the page on the user agent
	my $response = $ua->get($url);

	# Check for proper code, token, then the body content
	my $verified = $response->code == 200
		&& $response->header('X-Token') eq $token
		&& $response->content eq $body;

	# Perform test
	ok($verified, $message) or diag explain $response->as_string;
};

# Subroutine to generate a response subroutine
my $gen_response = sub {
	my $body = shift;

	# Return a generated subroutine
	return sub {
		return [200, ['Content-Type' => 'text/plain', 'X-Token' => $token], [$body]];
	};
};

# Set a simple request to be handled
$conf->override_request(
	url => 'http://localhost/echo_uri',
	$gen_response->('echo'),
);
$conf->override_request(
	url => 'http://localhost/jazz_hands',
	$gen_response->('spladow!'),
);
$conf->override_request(
	uri => 'https://localhost/jazz_hands',
	$gen_response->('SECURE spladow!'),
);

# Install the overrides
$conf->install_in_user_agent($ua);

$check_page->('http://localhost/echo_uri'   , 'echo', 'Echo page intercepted');
$check_page->('http://localhost/jazz_hands' , 'spladow!', 'Jazz hands are OK');
$check_page->('https://localhost/jazz_hands', 'SECURE spladow!', 'Jazz hands are secured');

exit 0;
