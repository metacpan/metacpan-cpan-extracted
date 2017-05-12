#!perl -T

use lib 't/lib';

use Test::More tests => 5;

use HTTP::Request;
use HTTP::Response;
use Test::Override::UserAgent for => 'testing';

# Create a configuration
my $conf = Test::Override::UserAgent->new->override_request(
	host => 'localhost',
	path => '/here',
	sub { return [200, [], []]; },
)->override_request(
	host => 'localhost',
	path => '/request',
	sub {
		my $response = HTTP::Response->new(200, 'OK', undef, undef);

		# Add the request to the response
		$response->request(shift);

		return $response;
	},
);

# Make a request object
my $request = HTTP::Request->new(GET => 'http://localhost/here');

# The request was handled
ok defined $conf->handle_request($request),
	'Found matching override';

# Response worked
is $conf->handle_request($request)->request, $request,
	'The self-added request is there';

# Change the URI
$request->uri('http://localhost/nothere');

# The request was not handled
ok !defined $conf->handle_request($request),
	'Did not find matching override';

# The request was not handled
isa_ok $conf->handle_request($request, live_request_handler => sub {}),
	'HTTP::Response',
	'No override and no live with live_request_handler';

# Change the URI
$request->uri('http://localhost/request');

# Response worked
is $conf->handle_request($request)->request, $request,
	'The pre-added request is there';
