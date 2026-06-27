package Thunderhorse::Response;
$Thunderhorse::Response::VERSION = '0.106';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Thunderhorse;

extends 'PAGI::Response';
with 'Thunderhorse::Message';

sub FOREIGNBUILDARGS ($class, %args)
{
	Gears::X::Thunderhorse->raise('no context for response')
		unless $args{context};

	return ($args{context}->pagi->[0]);
}

sub update ($self, $scope, $receive, $send)
{
	$self->{scope} = $scope;
}

sub _allows_empty_body ($self, $status)
{
	# HTTP protocol hardcodes - these statuses can have empty bodies
	return $status < 200
		|| $status == 204
		|| ($status >= 300 && $status < 400);
}

sub is_ready ($self)
{
	return true if $self->has_body_source;

	return $self->_allows_empty_body($self->status)
		if $self->has_status;

	return false;
}

__END__

=head1 NAME

Thunderhorse::Response - Response wrapper for Thunderhorse

=head1 SYNOPSIS

	async sub show ($self, $ctx, $id)
	{
		$ctx->res->text("Hello World");
		$ctx->res->json({data => 'value'});
		$ctx->res->redirect('/login');
	}

=head1 DESCRIPTION

Thunderhorse::Response is a thin wrapper around L<PAGI::Response> that
integrates with L<Thunderhorse::Context>. It provides a fluent interface for
building HTTP responses, including JSON, HTML, redirects, and file
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

	$res->update($scope, $receive, $send)

Updates the internal PAGI scope. Called automatically when the context's PAGI
tuple changes via setter of L<Thunderhorse::Context/pagi>.

=head3 is_ready

	$bool = $res->is_ready()

Returns whether this response is ready as far as Thunderhorse is concerned.
Responses which are ready will cause the context to become consumed after the
route handler returns.

Response is ready if it has a body, or if it has a status which does not
require body like C<204 No Content> or C<3XX>.

=head1 SEE ALSO

L<Thunderhorse>, L<PAGI::Response>, L<Thunderhorse::Context>

