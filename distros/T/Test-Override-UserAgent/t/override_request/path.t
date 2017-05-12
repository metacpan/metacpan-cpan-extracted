#!perl -T

use Test::More 0.88 tests => 7;

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
	path => '/robots.txt',
	$gen_response->('robots.txt everywhere'),
);
$conf->override_request(
	path => '/',
	$gen_response->('Root index'),
);
$conf->override_request(
	path => '/Case/Matters.HTML',
	$gen_response->('Check casing'),
);

# Install the overrides
$conf->install_in_user_agent($ua);

$check_page->('http://localhost/'                 , 'Root index');
$check_page->('https://example.com/robots.txt'    , 'robots.txt everywhere');
$check_page->('http://localhost:8888/'            , 'Root index', 'Root index on port 8888');
$check_page->('http://localhost/README'           , undef, 'README not overwritten');
$check_page->('ftp://localhost/robots.txt'        , 'robots.txt everywhere', 'robots.txt on FTP');
$check_page->('http://localhost/Case/Matters.HTML', 'Check casing', 'Paths are case-sensative');
$check_page->('http://localhost/Case/Matters.html', undef, 'Paths are case-sensative');

exit 0;
