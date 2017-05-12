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

	# Default message to the body
	$message ||= $body;

	# Request the page on the user agent
	my $response = $ua->get($url);

	# Check for proper code, token, then the body content
	my $verified = defined $body
		? $response->code == 200
			&& $response->header('X-Token') eq $token
			&& $response->content eq $body
		: $response->code == 404
			&& $response->header('Client-Warning') eq 'Internal response'
			&& $response->header('Client-Response-Source') eq 'Test::Override::UserAgent'
		;

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
	host => 'localhost',
	$gen_response->('This is localhost'),
);
$conf->override_request(
	host => 'example.com',
	$gen_response->('This is example.com'),
);

# Install the overrides
$conf->install_in_user_agent($ua);

$check_page->('http://localhost/wat'             , 'This is localhost', 'localhost override');
$check_page->('http://example.com/robots.txt'    , 'This is example.com', 'example.com override');
$check_page->('http://www.example.com/robots.txt', undef, 'www.example.com not overwritten');

exit 0;
