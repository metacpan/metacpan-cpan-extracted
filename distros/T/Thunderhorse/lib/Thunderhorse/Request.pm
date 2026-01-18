package Thunderhorse::Request;
$Thunderhorse::Request::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

use Future::AsyncAwait;
use Gears::X::Thunderhorse;
use List::Util qw(mesh);

extends 'PAGI::Request';
with 'Thunderhorse::Message';

sub FOREIGNBUILDARGS ($class, %args)
{
	Gears::X::Thunderhorse->raise('no context for response')
		unless $args{context};

	return $args{context}->pagi->@[0, 1];
}

sub update ($self, $scope, $receive, $send)
{
	$self->{scope} = $scope;
	$self->{receive} = $receive;

	# handling next match, so make sure path_params are invalidated
	delete $self->{path_params};
}

sub path_params ($self)
{
	return $self->{path_params} //= do {
		my $ctx = $self->context;
		my $match = $ctx->match;
		$match = $match->[0]
			if ref $match eq 'ARRAY';

		my $pattern = $match->location->pattern_obj;
		my $matched = $match->matched;
		+{mesh [map { $_->{label} } $pattern->tokens->@*], $matched};
	};
}

__END__

=head1 NAME

Thunderhorse::Request - Request wrapper for Thunderhorse

=head1 SYNOPSIS

	async sub show ($self, $ctx, $id)
	{
		my $param = $ctx->req->param('name');
		my $method = $ctx->req->method;
		my $body = await $ctx->req->json;
	}

=head1 DESCRIPTION

Thunderhorse::Request is a thin wrapper around L<PAGI::Request> that integrates
with L<Thunderhorse::Context>. It provides access to all HTTP request data
including headers, query parameters, cookies, and request body.

This class extends L<PAGI::Request> and mixes in C<Thunderhorse::Message> to
provide context integration.

=head1 INTERFACE

Inherits all interface from L<PAGI::Request>, and
adds the interface documented below.

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

	$req->update()

Updates the internal PAGI scope and receiver from the context's PAGI tuple.
Called automatically when the context's PAGI tuple changes via
setter of L<Thunderhorse::Context/pagi>.

=head1 SEE ALSO

L<Thunderhorse>, L<PAGI::Request>, L<Thunderhorse::Context>

