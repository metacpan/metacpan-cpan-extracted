package Thunderhorse::SSE;
$Thunderhorse::SSE::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Future::AsyncAwait;
use Gears::X::Thunderhorse;

extends 'PAGI::SSE';
with 'Thunderhorse::Message';

sub FOREIGNBUILDARGS ($class, %args)
{
	Gears::X::Thunderhorse->raise('no context for sse')
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

Thunderhorse::SSE - Server-Sent Events wrapper for Thunderhorse

=head1 SYNOPSIS

	async sub handle ($self, $ctx)
	{
		my $sse = $ctx->sse;
		await $sse->keepalive(30);

		await $sse->every(2, async sub {
			await $sse->send_json({time => time()});
		});
	}

=head1 DESCRIPTION

Thunderhorse::SSE is a thin wrapper around L<PAGI::SSE> that integrates with
L<Thunderhorse::Context>. It provides a high-level API for Server-Sent Events
connections including multiple send methods, connection state tracking, and
cleanup callbacks.

This class extends L<PAGI::SSE> and mixes in C<Thunderhorse::Message> to
provide context integration.

=head1 INTERFACE

Inherits all interface from L<PAGI::SSE>, and adds the interface documented
below.

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

	$sse->update()

Updates the internal PAGI scope, receiver, and sender from the context's PAGI
tuple. Called automatically when the context's PAGI tuple changes via
setter of L<Thunderhorse::Context/pagi>.

=head1 SEE ALSO

L<Thunderhorse>, L<PAGI::SSE>, L<Thunderhorse::Context>

