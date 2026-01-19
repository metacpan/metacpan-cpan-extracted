package Thunderhorse::WebSocket;
$Thunderhorse::WebSocket::VERSION = '0.102';
use v5.40;
use Mooish::Base -standard;

use Future::AsyncAwait;
use Gears::X::Thunderhorse;

extends 'PAGI::WebSocket';
with 'Thunderhorse::Message';

sub FOREIGNBUILDARGS ($class, %args)
{
	Gears::X::Thunderhorse->raise('no context for websocket')
		unless $args{context};

	return $args{context}->pagi->@*;
}

sub update ($self, $scope, $receive, $send)
{
	$self->{scope} = $scope;
	$self->{receive} = $receive;
	$self->{send} = $send;
}

__END__

=head1 NAME

Thunderhorse::WebSocket - WebSocket wrapper for Thunderhorse

=head1 SYNOPSIS

	async sub handle ($self, $ctx)
	{
		my $ws = $ctx->ws;
		await $ws->accept;

		await $ws->each_json(async sub ($data) {
			await $ws->send_json({echo => $data});
		});
	}

=head1 DESCRIPTION

Thunderhorse::WebSocket is a thin wrapper around L<PAGI::WebSocket> that
integrates with L<Thunderhorse::Context>. It provides a high-level API for
WebSocket connections including typed send/receive methods, connection state
tracking, and cleanup callbacks.

This class extends L<PAGI::WebSocket> and mixes in C<Thunderhorse::Message> to
provide context integration.

=head1 INTERFACE

Inherits all interface from L<PAGI::WebSocket>, and adds the interface
documented below.

=head2 Attributes

=head3 context

The L<Thunderhorse::Context> object for this request (weakened).

I<Required in the constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

Standard Mooish constructor. Consult L</Attributes> section for available
constructor arguments.

=head3 update

	$ws->update()

Updates the internal PAGI scope, receiver, and sender from the context's PAGI
tuple. Called automatically when the context's PAGI tuple changes via
setter of L<Thunderhorse::Context/pagi>.

=head1 SEE ALSO

L<Thunderhorse>, L<PAGI::WebSocket>, L<Thunderhorse::Context>

