package Thunderhorse::Context;
$Thunderhorse::Context::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Devel::StrictMode;

use Thunderhorse::Request;
use Thunderhorse::Response;
use Thunderhorse::WebSocket;
use Thunderhorse::SSE;

extends 'Gears::Context';

has param 'pagi' => (
	(STRICT ? (isa => Tuple [HashRef, CodeRef, CodeRef]) : ()),
	writer => -hidden,
);

# match structure is recursive
has field 'match' => (
	(STRICT ? (isa => (InstanceOf ['Gears::Router::Match']) | ArrayRef) : ()),
	writer => 1,
);

has field 'req' => (
	(STRICT ? (isa => InstanceOf ['Thunderhorse::Request']) : ()),
	default => sub ($self) { Thunderhorse::Request->new(context => $self) },
	handles => [qw(stash)],
);

has field 'res' => (
	(STRICT ? (isa => InstanceOf ['Thunderhorse::Response']) : ()),
	default => sub ($self) { Thunderhorse::Response->new(context => $self) },
);

# NOTE: websocket must be lazy, because it will die if scope is not websocket
has field 'ws' => (
	(STRICT ? (isa => InstanceOf ['Thunderhorse::WebSocket']) : ()),
	predicate => 1,
	lazy => sub ($self) { Thunderhorse::WebSocket->new(context => $self) },
);

# NOTE: sse must be lazy, because it will die if scope is not sse
has field 'sse' => (
	(STRICT ? (isa => InstanceOf ['Thunderhorse::SSE']) : ()),
	predicate => 1,
	lazy => sub ($self) { Thunderhorse::SSE->new(context => $self) },
);

has field '_consumed' => (
	(STRICT ? (isa => Bool) : ()),
	writer => 1,
	default => false,
);

sub update ($self, $scope, $receive, $send)
{
	$self->_set_pagi([$scope, $receive, $send]);

	$self->req->update($scope, $receive, $send);
	$self->res->update($scope, $receive, $send);

	$self->ws->update($scope, $receive, $send)
		if $self->has_ws;

	$self->sse->update($scope, $receive, $send)
		if $self->has_sse;

	return;
}

sub scope ($self)
{
	return $self->pagi->[0];
}

sub receiver ($self)
{
	return $self->pagi->[1];
}

sub sender ($self)
{
	return $self->pagi->[2];
}

sub consume ($self)
{
	$self->_set_consumed(true);
	return $self;
}

sub is_consumed ($self)
{
	return $self->_consumed
		|| $self->res->is_sent
		|| ($self->has_ws && $self->ws->is_closed)
		|| ($self->has_sse && $self->sse->is_closed);
}

__END__

=head1 NAME

Thunderhorse::Context - Request handling context

=head1 SYNOPSIS

	async sub show ($self, $ctx, $id)
	{
		my $query_param = $ctx->req->query('name');
		my $stashed_value = $ctx->stash->{key};

		await $ctx->res->text("Hello World");
	}

=head1 DESCRIPTION

Thunderhorse::Context represents the context of a single HTTP request. It
extends L<Gears::Context> and provides access to the request, response,
WebSocket connection, and Server-Sent Events stream. Each context manages the
lifecycle of request processing.

The context object is passed to route handlers and provides the primary
interface for interacting with the HTTP request and generating responses.

Since this object is created for every request, costly type checks are disabled
conditionally with the help of L<Devel::StrictMode>. Refer to its documentation
to learn how they can be enabled on demand.

=head1 INTERFACE

Inherits all interface from L<Gears::Context>, and adds the interface
documented below.

=head2 Attributes

=head3 pagi

A tuple C<[HashRef, CodeRef, CodeRef]> containing the PAGI scope hash,
receiver, and sender.

I<Required in the constructor>

=head3 match

The router match object (L<Gears::Router::Match>) or array ref containing
match information for the current route.

B<writer:> C<set_match>

=head3 req

The L<Thunderhorse::Request> object for this context. Created automatically
with a reference to this context.

=head3 res

The L<Thunderhorse::Response> object for this context. Created automatically
with a reference to this context.

=head3 ws

The L<Thunderhorse::WebSocket> object for this context. Created lazily when
first accessed and will throw an exception if the PAGI scope is not a
WebSocket scope.

B<predicate:> C<has_ws>

=head3 sse

The L<Thunderhorse::SSE> object for this context. Created lazily when first
accessed and will throw an exception if the PAGI scope is not a Server-Sent
Events scope.

B<predicate:> C<has_sse>

=head2 Methods

=head3 new

	$object = $class->new(%args)

Standard Mooish constructor. Consult L</Attributes> section for available
constructor arguments.

=head3 stash

Delegated method for L<PAGI::Request/stash>

=head3 scope

	$scope = $ctx->scope()

Returns the PAGI scope hash (the first element of the PAGI tuple).

=head3 receiver

	$receiver = $ctx->receiver()

Returns the PAGI receiver callback (the second element of the PAGI tuple).

=head3 sender

	$sender = $ctx->sender()

Returns the PAGI sender callback (the third element of the PAGI tuple).

=head3 update

	$ctx->update($scope, $receive, $send)

Updates PAGI tuple elements in the context and in all subobjects (request,
response, sse, websocket). This is done automatically before a route handler is
called.

=head3 consume

	$ctx->consume()

Marks the context as consumed, preventing further processing. Returns the
context object for chaining.

=head3 is_consumed

	$bool = $ctx->is_consumed()

Returns true if the context has been consumed either explicitly via
L</consume>, or implicitly by sending a response, closing a WebSocket
connection, or closing an SSE stream.

=head1 SEE ALSO

L<Thunderhorse>, L<Gears::Context>, L<Thunderhorse::Request>,
L<Thunderhorse::Response>, L<Thunderhorse::WebSocket>, L<Thunderhorse::SSE>

