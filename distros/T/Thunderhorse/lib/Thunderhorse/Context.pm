package Thunderhorse::Context;
$Thunderhorse::Context::VERSION = '0.001';
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

sub set_pagi ($self, $new)
{
	$self->_set_pagi($new);

	$self->req->update;
	$self->res->update;

	$self->ws->update
		if $self->has_ws;

	$self->sse->update
		if $self->has_sse;
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

