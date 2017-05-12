#!perl -T

use Test::More 0.88 tests => 3;

use HTTP::Request;
use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

# Make a new override
my $conf = Test::Override::UserAgent->new;

# Generate a random number to add as a token
my $token = rand();

# Create a new user agent
my $ua = LWP::UserAgent->new(timeout => 2);

# Subroutine to check the page result
my $check_page_method = sub {
	my ($method, $body, $message) = @_;

	# Default message to the body
	$message ||= $body;

	# Request the page on the user agent
	my $response = $ua->request(HTTP::Request->new($method, 'http://localhost/'));

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
	ok($verified, $message)
		or diag explain join qq{\n}, $response->request->as_string, $response->as_string;
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
	method => 'GET',
	$gen_response->('GET request'),
);
$conf->override_request(
	method => 'post',
	$gen_response->('POST request'),
);
$conf->override_request(
	method => 'PUT',
	$gen_response->('PUT request'),
);

# Install the overrides
$conf->install_in_user_agent($ua);

$check_page_method->('GET' , 'GET request');
$check_page_method->('POST', undef, 'Method is case-sensative');
$check_page_method->('PUT' , 'PUT request');

exit 0;
