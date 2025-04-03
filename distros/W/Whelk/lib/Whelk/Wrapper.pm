package Whelk::Wrapper;
$Whelk::Wrapper::VERSION = '1.03';
use Kelp::Base;

use Try::Tiny;
use Scalar::Util qw(blessed);
use HTTP::Status qw(status_message);
use Kelp::Exception;
use Whelk::Schema;
use Whelk::Exception;

sub inhale_request
{
	my ($self, $app, $endpoint, @args) = @_;
	my $req = $app->req;
	my $inhaled;

	my $params = $endpoint->parameters;

	if ($params->path_schema) {
		$params->path_schema->inhale_or_error(
			$req->named,
			sub {
				Whelk::Exception->throw(422, hint => "Path parameters error at: $_[0]");
			}
		);
	}

	if ($params->query_schema) {
		my $new_query = $params->query_schema->inhale_exhale(
			$req->query_parameters->mixed,
			sub {
				Whelk::Exception->throw(422, hint => "Query parameters error at: $_[0]");
			}
		);

		# adjust the parameters in the request itself to allow all calls of
		# ->param and ->query_param to just work
		$req->query_parameters->clear->merge_mixed($new_query);
		$req->parameters->clear->merge_mixed($new_query)->merge_mixed($req->body_parameters->mixed);
	}

	if ($params->header_schema) {
		my %headers;
		foreach my $key ($req->headers->header_field_names) {
			my @values = map { split /, /, $_ } $req->header($key);
			$headers{$key} = @values == 1 ? $values[0] : \@values;
		}

		$params->header_schema->inhale_or_error(
			\%headers,
			sub {
				Whelk::Exception->throw(422, hint => "Header parameters error at: $_[0]");
			}
		);
	}

	if ($params->cookie_schema) {
		$params->cookie_schema->inhale_or_error(
			$req->cookies,
			sub {
				Whelk::Exception->throw(422, hint => "Cookie parameters error at: $_[0]");
			}
		);
	}

	if ($endpoint->request) {
		$req->stash->{request} = $endpoint->request->inhale_exhale(
			$endpoint->formatter->get_request_body($app),
			sub {
				Whelk::Exception->throw(422, hint => "Content error at: $_[0]");
			}
		);
	}
}

sub exhale_response
{
	my ($self, $app, $endpoint, $response, $inhale_error) = @_;
	my $code = $app->res->code;
	my $schema = $self->map_code_to_schema($endpoint, $code);
	my $path = $endpoint->path;

	if ($schema && $schema->empty) {
		if ($self->_get_code_class($code) ne '2XX') {
			die "gave up trying to find a non-empty schema for $path"
				if $code == 500;

			$app->res->set_code(500);
			my $error = $self->on_error($app, "empty schema for non-success code in $path (code $code)");
			return $self->exhale_response($app, $endpoint, $error);
		}
	}
	else {
		$response = $self->wrap_response($response, $code);
	}

	if (!$schema) {

		# make sure not to loop if code is already 500
		Kelp::Exception->throw(508, body => "gave up trying to find a schema for $path")
			if $code == 500;

		$app->res->set_code(500);
		my $error = $self->on_error($app, "no data schema for $path (code $code)");
		return $self->exhale_response($app, $endpoint, $error);
	}

	# try inhaling
	if ($app->whelk->inhale_response) {
		my $inhaled = $schema->inhale($response);
		if (defined $inhaled) {

			# If this is an error with inhaling itself, we have to resort to
			# throwing an exception to avoid an infinite recursion. This may
			# happen if the wrapper code has a bug in wrap_error and
			# build_response_schemas.
			die "gave up trying to inhale error response for $path: $inhaled"
				if $inhale_error;

			# otherwise, we can exhale_response again, this time with an error
			$app->res->set_code(500);
			my $error = $self->on_error($app, "response schema validation failed for $path: $inhaled");
			return $self->exhale_response($app, $endpoint, $error, 1);
		}
	}

	return $schema->exhale($response);
}

sub execute
{
	my ($self, $app, $endpoint, @args) = @_;

	my ($success, $data);
	try {
		$self->inhale_request($app, $endpoint);
		$data = $endpoint->code->($app->context->current, @args);
		$success = 1;
	}
	catch {
		$data = $_;
		$success = 0;
	};

	return ($success, $data);
}

sub prepare_response
{
	my ($self, $app, $endpoint, $success, $data) = @_;
	my $res = $app->res;

	# decide on the resulting code and data based on status
	if ($success) {
		$res->set_code($endpoint->response_code) unless $res->code;
	}
	else {
		if (blessed $data && $data->isa('Kelp::Exception')) {

			# Whelk exceptions are API exceptions and will yield API responses if
			# possible. Kelp exceptions are application exceptions and will yield a
			# regular error page.
			$data->throw unless $data->isa('Whelk::Exception');
			$res->set_code($data->code);
			$data = $data->hint // $self->on_error($app, $data->body);
		}
		else {
			$res->set_code(500);
			$data = $self->on_error($app, $data);
		}
	}

	return $self->exhale_response($app, $endpoint, $data);
}

sub _get_code_class
{
	my ($self, $code) = @_;

	substr $code, 1, 2, 'XX';
	return $code;
}

sub map_code_to_schema
{
	my ($self, $endpoint, $code) = @_;

	my $schemas = $endpoint->response_schemas;
	return $schemas->{$code} // $schemas->{$self->_get_code_class($code)};
}

sub wrap_response
{
	my ($self, $data, $code) = @_;
	state $map = {
		'2XX' => 'success',
		'4XX' => 'client_error',
		'5XX' => 'server_error',
	};

	my $code_class = $self->_get_code_class($code);
	my $method = "wrap_$map->{$code_class}";

	return $self->$method($data);
}

sub on_error
{
	my ($self, $app, $data) = @_;

	$app->logger(error => $data)
		if $app->can('logger');

	return status_message($app->res->code);
}

sub wrap
{
	my ($self, $endpoint) = @_;
	$self->build_response_schemas($endpoint);

	return sub {
		my $app = shift->context->app;

		my $prepared = $self->prepare_response(
			$app,
			$endpoint,
			$self->execute($app, $endpoint, @_),
		);

		return $endpoint->formatter->format_response($app, $prepared);
	};
}

sub wrap_server_error
{
	my ($self, $error) = @_;

	...;
}

sub wrap_client_error
{
	my ($self, $error) = @_;

	return $self->wrap_server_error($error);
}

sub wrap_success
{
	my ($self, $data) = @_;

	...;
}

sub build_response_schemas
{
	my ($self, $endpoint) = @_;

	...;
}

1;

__END__

=pod

=head1 NAME

Whelk::Wrapper - Base class for wrappers

=head1 SYNOPSIS

	package Whelk::Wrapper::MyWrapper;

	use Kelp::Base 'Whelk::Wrapper';

	# at the very least, there three methods must be implemented

	sub wrap_server_error
	{
		my ($self, $error) = @_;

		...;
	}

	sub wrap_success
	{
		my ($self, $data) = @_;

		...;
	}

	sub build_response_schemas
	{
		my ($self, $endpoint) = @_;

		...;
	}

=head1 DESCRIPTION

Whelk::Wrapper is a base class for wrappers. Wrapper's job is to wrap the
endpoint handler in necessary logic: validating request and response data,
adding extra data to responses and error handling. Wrappers do not handle
encoding requests and responses (for example with C<JSON>), that's a job for
L<Whelk::Formatter>.

In addition, wrapper decides how to treat failures. It defines schemas for
errors with status classes 4XX and 5XX and uses those instead of response
schema defined for the endpoint in case an error occurs.

Whelk implements two basic wrappers which can be used out of the box:
L<Whelk::Wrapper::Simple> (the default) and L<Whelk::Wrapper::WithStatus>. They
are very similar and differ in how they wrap the response data - C<WithStatus>
wrapper introduces an extra boolean C<status> field to every response.

It should be pretty easy to subclass a wrapper if needed. Take a look at the
built in subclasses and at the code of this class to get the basic idea.

=head1 METHODS

The only wrapper method called from outside is C<wrap>. All the other methods
are helpers which make it easier to adjust the behavior without rewriting it
from scratch.

The base C<Whelk::Wrapper> class does not implement C<wrap_server_error>,
C<wrap_success> and C<build_response_schemas> methods - they have to be
implemented in a subclass.

=head2 wrap

	my $wrapped_sub = $wrapper->wrap($sub);

Takes a reference to a subroutine and returns a reference to another
subroutine. The returned subroutine is an outer code to be called by Kelp as
route handler. It does all the Whelk-specific behavior and calls the inner
subroutine to get the actual result of the API call.

=head2 wrap_response

	my $response = $wrapper->wrap_response($response, $http_code);

This method is used to wrap C<$response> returned by Kelp route handler. The
default implementation takes a look at the C<$http_code> and fires one of
C<wrap_success> (for codes 2XX), C<wrap_server_error> (for codes 5XX) or
C<wrap_client_error> (for codes 4XX). The wrapped response must be matching the
respone schema defined in L</build_response_schemas> or else an exception will
be thrown.

=head2 build_response_schemas

	$wrapper->build_response_schemas($endpoint)

Takes an object of L<Whelk::Endpoint> class and should set C<response_schemas>
field of that object. That field must contain a hash reference where each key
will be response code and each value will be a schema built using
L<Whelk::Schema/build>. Regular success schema should nest the value of C<<
$endpoint->response >> schema inside of it.

The status codes need not to be exact. By default, only their class is
important (C<2XX>, C<4XX> or C<5XX>). The exact semantics of that mapping is
defined in another method, L</map_code_to_schema>.

If the schema from C<< $endpoint->response >> is empty via C<<
$endpoint->response->empty >> then it must be added to C<response_schemas> as
is to correctly be mapped to C<204 No Body> HTTP status.

=head2 inhale_request

This is a helper method which validates the request. It may be overridden for
extra behavior.

To ensure C<request_body> method works, it must set C<<
$app->req->stash->{request} >> after validating and cleaning the request body.

=head2 execute

This is a helper method which runs the actual route handler in a try/catch
block. It may be overridden for extra behavior.

=head2 prepare_response

This is a helper method which prepares a response to be passed to
L</exhale_response>. It may be overridden for extra behavior.

=head2 exhale_response

This is a helper method which validates and returns a response. It may be
overridden for extra behavior.

=head2 map_code_to_schema

This is a helper method which decides which key from C<response_schemas> of the
endpoint to use based on HTTP code of the response. It may be overridden for
extra behavior.

=head2 on_error

This is a helper method which decides what to do when an unexpected error
occurs. By default, it creates an application log and modifies the result
message to return a stock HTTP message like C<Internal Server Error>. It may be
overridden for extra behavior.

