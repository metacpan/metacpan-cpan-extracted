package Thunderhorse::Response;
$Thunderhorse::Response::VERSION = '0.102';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Thunderhorse;

extends 'PAGI::Response';
with 'Thunderhorse::Message';

sub FOREIGNBUILDARGS ($class, %args)
{
	Gears::X::Thunderhorse->raise('no context for response')
		unless $args{context};

	return $args{context}->pagi->@[0, 2];
}

sub update ($self, $scope, $receive, $send)
{
	$self->{scope} = $scope;
	$self->{send} = $send;
}

__END__

=head1 NAME

Thunderhorse::Response - Response wrapper for Thunderhorse

=head1 SYNOPSIS

	async sub show ($self, $ctx, $id)
	{
		await $ctx->res->text("Hello World");
		await $ctx->res->json({data => 'value'});
		await $ctx->res->redirect('/login');
	}

=head1 DESCRIPTION

Thunderhorse::Response is a thin wrapper around L<PAGI::Response> that
integrates with L<Thunderhorse::Context>. It provides a fluent interface for
building and sending HTTP responses, including JSON, HTML, redirects, and file
downloads.

This class extends L<PAGI::Response> and mixes in C<Thunderhorse::Message> to
provide context integration.

=head1 INTERFACE

Inherits all interface from L<PAGI::Response>, and adds the interface
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

	$res->update()

Updates the internal PAGI scope and sender from the context's PAGI tuple.
Called automatically when the context's PAGI tuple changes via
setter of L<Thunderhorse::Context/pagi>.

=head1 SEE ALSO

L<Thunderhorse>, L<PAGI::Response>, L<Thunderhorse::Context>

