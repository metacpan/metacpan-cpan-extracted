package Test2::Thunderhorse;
$Test2::Thunderhorse::VERSION = '0.100';
use v5.40;

use Test2::API qw(context);
use PAGI::Test::Client;
use Carp qw(croak);

use Exporter 'import';

our @EXPORT = qw(
	pagi_run
	http
	http_status_is
	http_header_is
	http_text_is
	websocket
	sse
);

die 'Error: Test2::Thunderhorse loaded in a PAGI environment'
	if ($ENV{PAGI_ENV} // 'test') ne 'test';
$ENV{PAGI_ENV} = 'test';

our $THIS_CLIENT;
my $LAST_HTTP;
my $LAST_WS;
my $LAST_SSE;

sub _build_client ($app, %args)
{
	return $THIS_CLIENT if defined $THIS_CLIENT;

	if (ref $app eq 'ARRAY') {
		%args = ($app->@[1, $app->$#*], app => $app->[0]->run, %args);
	}
	elsif (ref $app eq 'HASH') {
		%args = ($app->%*, %args);
	}
	else {
		$args{app} = $app->run;
	}

	$args{raise_app_exceptions} = true
		unless exists $args{raise_app_exceptions};

	return PAGI::Test::Client->new(%args);
}

sub pagi_run ($app, $code)
{
	my $client = _build_client($app, lifespan => true);
	local $THIS_CLIENT = $client;

	$client->start;
	$code->();
	$client->stop;

	return $client->state;
}

sub _http ($app, $http_request, %args)
{
	# Extract method and path
	my $method = lc $http_request->method;
	my $path = $http_request->uri->path_query;

	# Extract headers
	my %headers;
	$http_request->headers->scan(
		sub ($key, $value) {
			push $headers{$key}->@*, $value;
		}
	);

	$args{headers} = \%headers
		if %headers;

	# Extract body for POST/PUT/PATCH
	my $content = $http_request->content;
	$args{body} = $content
		if length $content // '';

	$LAST_HTTP = _build_client($app)->$method($path, %args);

	return $LAST_HTTP;
}

sub http (@args)
{
	return $LAST_HTTP // croak 'no last http in Test2::Thunderhorse'
		if @args == 0;

	return _http @args;
}

sub http_status_is ($expected)
{
	my $ctx = context();

	my $got = $LAST_HTTP->status;
	my $pass = $got == $expected;

	$ctx->ok($pass, 'status ok', ["expected: $expected", "got: $got"]);

	$ctx->release;
	return $pass;
}

sub http_text_is ($expected)
{
	my $ctx = context();

	my $got = $LAST_HTTP->text // '<NULL>';
	my $pass = $got eq $expected;

	$ctx->ok($pass, 'body ok', ["expected: $expected", "got: $got"]);

	$ctx->release;
	return $pass;
}

sub http_header_is ($header, $expected)
{
	my $ctx = context();

	my $got = $LAST_HTTP->header($header);
	my $pass = defined($got) && defined($expected) && $got eq $expected;

	$ctx->ok($pass, "$header header ok", ["expected: $expected", "got: $got"]);

	$ctx->release;
	return $pass;
}

sub _websocket ($app, $path, @args)
{
	$LAST_WS = _build_client($app)->websocket($path, @args);

	if ($LAST_WS->is_closed) {
		my $ctx = context();
		$ctx->fail("Connecting to websocket $path failed");
		$ctx->release;
	}

	return $LAST_WS;
}

sub websocket (@args)
{
	return $LAST_WS // croak 'no last websocket in Test2::Thunderhorse'
		if @args == 0;

	return _websocket @args;
}

sub _sse ($app, $path, @args)
{
	$LAST_SSE = _build_client($app)->sse($path, @args);

	if ($LAST_SSE->is_closed) {
		my $ctx = context();
		$ctx->fail("Connecting to sse $path failed");
		$ctx->release;
	}

	return $LAST_SSE;
}

sub sse (@args)
{
	return $LAST_SSE // croak 'no last sse in Test2::Thunderhorse'
		if @args == 0;

	return _sse @args;
}

1;

__END__

=head1 NAME

Test2::Thunderhorse - Test2-native testing tools for Thunderhorse applications

=head1 SYNOPSIS

	use v5.40;
	use Test2::V1;
	use Test2::Thunderhorse;
	use HTTP::Request::Common;

	package MyApp {
		use Mooish::Base -standard;
		extends 'Thunderhorse::App';

		sub build ($self) {
			$self->router->add(
				'/hello' => {
					to => sub ($self, $ctx) {
						return 'Hello World';
					}
				}
			);
		}
	}

	my $app = MyApp->new;

	# Test HTTP endpoints
	http $app, GET '/hello';
	http_status_is 200;
	http_header_is 'Content-Type', 'text/html; charset=utf-8';
	http_text_is 'Hello World';

	# Test WebSocket connections
	websocket $app, '/ws/echo';
	websocket->send_text('test');
	is websocket->receive_text, 'echo: test';
	websocket->close;

	# Test Server-Sent Events
	sse $app, '/events';
	is sse->receive_event->{data}, 'message';
	sse->close;

	done_testing;

=head1 DESCRIPTION

Test2::Thunderhorse provides a Test2-native interface for testing Thunderhorse
applications. It wraps L<PAGI::Test::Client> and provides convenient exported
functions for testing HTTP requests, WebSocket connections, and Server-Sent
Events streams.

The module automatically sets C<PAGI_ENV> to C<test> and prevents loading in
non-test environments. All exported functions integrate with Test2's context
system for proper test result reporting.

=head1 EXPORTED FUNCTIONS

=head2 pagi_run

	my $state = pagi_run $app, $coderef;

Fires a PAGI startup lifecycle event, then executes the C<$coderef>. This
triggers C<on_startup> and C<on_shutdown> hooks in Thunderhorse, and may be
mandatory depending on the app configuration. Inside C<$coderef>, test the app
normally using other functions.

Returns the shared state from lifespan.

=head2 http

	http $app, GET '/path';
	http $app, POST '/path', Content => 'data';

	my $response = http;

Makes an HTTP request to the application and stores the response as the current
HTTP response. When called without arguments, returns the last HTTP response
object.

The first argument is the Thunderhorse application object. The second argument
is an L<HTTP::Request> object, typically created using L<HTTP::Request::Common>
functions like C<GET>, C<POST>, C<PUT>, C<DELETE>, etc.

The returned response object is a L<PAGI::Test::Response> object with
methods like C<status>, C<text>, C<json>, C<header>, etc.

=head2 http_status_is

	http_status_is 200;
	http_status_is 404;

Tests that the last HTTP response status code matches the expected value. This
is a Test2 assertion that will pass or fail appropriately.

This helper is here to test a common case of comparing the HTTP status code. It
works the same as C<< is http->status, $status, 'status ok' >>. Use C<<
http->status >> with other Test2 tools to do more complex comparisons.

=head2 http_header_is

	http_header_is 'Content-Type', 'text/html; charset=utf-8';
	http_header_is 'X-Custom-Header', 'value';

Tests that a specific header in the last HTTP response matches the expected
value. This is a Test2 assertion.

This helper is here to test a common case of comparing the HTTP header's value.
It works the same as C<< is http->header($header), $value, "$header header ok"
>>. Use C<< http->header >> with other Test2 tools to do more complex
comparisons.

=head2 http_text_is

	http_text_is 'Hello World';
	http_text_is '{"status":"ok"}';

Tests that the body of the last HTTP response matches the expected value. This
is a Test2 assertion.

This helper is here to test a common case of comparing the HTTP body. It
works the same as C<< is http->text, $body, 'body ok' >>. Use C<<
http->text >> with other Test2 tools to do more complex comparisons.

=head2 websocket

	websocket $app, '/ws/path';
	websocket $app, '/ws/path', headers => {...};

	my $ws = websocket;

Opens a WebSocket connection to the application and stores it as the current
WebSocket connection. When called without arguments, returns the last WebSocket
connection object.

The first argument is the Thunderhorse application object. The second argument
is the WebSocket endpoint path. Additional arguments are passed as options to
the underlying client.

If the WebSocket connection fails to establish, a test failure is recorded.

The returned WebSocket object is a L<PAGI::Test::WebSocket> object with
methods like:

=over

=item * C<send_text($text)> - Send text message

=item * C<send_json($data)> - Send JSON message

=item * C<receive_text> - Receive text message

=item * C<receive_json> - Receive and decode JSON message

=item * C<close> - Close the connection

=item * C<is_closed> - Check if connection is closed

=back

=head2 sse

	sse $app, '/events/path';
	sse $app, '/events/path', headers => {...};

	my $sse = sse;

Opens a Server-Sent Events connection to the application and stores it as the
current SSE connection. When called without arguments, returns the last SSE
connection object.

The first argument is the Thunderhorse application object. The second argument
is the SSE endpoint path. Additional arguments are passed as options to the
underlying client.

If the SSE connection fails to establish, a test failure is recorded.

The returned SSE object is a L<PAGI::Test::SSE> object with methods
like:

=over

=item * C<receive_event> - Receive next event as hashref with keys: C<data>,
C<event>, C<id>

=item * C<receive_json> - Receive and decode JSON from next event's data

=item * C<close> - Close the connection

=item * C<is_closed> - Check if connection is closed

=back

=head1 TESTING PATTERNS

=head2 Basic HTTP Testing

	subtest 'should handle GET request' => sub {
		http $app, GET '/api/users';
		http_status_is 200;
		http_header_is 'Content-Type', 'application/json; charset=utf-8';

		my $data = http->json;
		is scalar($data->@*), 3, 'got 3 users';
	};

=head2 Testing with POST Data

	subtest 'should create user' => sub {
		http $app, POST '/api/users',
			Content_Type => 'application/json',
			Content => '{"name":"John"}';

		http_status_is 201;
		http_text_is '{"status":"created"}';
	};

=head2 WebSocket Testing

	subtest 'should echo messages' => sub {
		websocket $app, '/ws/echo';

		websocket->send_text('hello');
		is websocket->receive_text, 'echo: hello';

		websocket->send_json({msg => 'test'});
		is websocket->receive_json, {msg => 'test', echoed => 1};

		websocket->close;
		ok websocket->is_closed;
	};

=head2 SSE Testing

	subtest 'should stream events' => sub {
		sse $app, '/events/stream';

		my $event = sse->receive_event;
		is $event->{data}, 'first message';
		is $event->{event}, 'update';
		is $event->{id}, 1;

		my $json = sse->receive_json;
		is $json->{count}, 42;

		sse->close;
	};

=head1 ENVIRONMENT

The module automatically sets C<PAGI_ENV> to C<test> when loaded and will die
if loaded in an environment where C<PAGI_ENV> is already set to something other
than C<test>. This ensures tests always run in test mode.

=head1 SEE ALSO

L<Test2::V1>, L<PAGI::Test::Client>, L<Thunderhorse>, L<HTTP::Request::Common>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

