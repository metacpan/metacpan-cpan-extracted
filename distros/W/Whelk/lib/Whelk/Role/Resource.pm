package Whelk::Role::Resource;
$Whelk::Role::Resource::VERSION = '1.02';
use Kelp::Base -attr;
use Role::Tiny;

use Carp;
use Whelk::Endpoint;

requires qw(api context);

sub _whelk_config
{
	my ($self, $key) = @_;

	return $self->context->app->whelk->resources->{ref $self}{$key};
}

sub _whelk_adjust_pattern
{
	my ($self, $pattern) = @_;

	# we don't handle regex
	croak 'Regex patterns are disallowed in Whelk'
		unless !ref $pattern;

	# glue up the route from base and used patterns
	$pattern = $self->_whelk_config('base_route') . $pattern;
	$pattern =~ s{/$}{};
	$pattern =~ s{/+}{/};

	return $pattern;
}

sub _whelk_adjust_to
{
	my ($self, $to) = @_;

	my $base = $self->context->app->routes->base;
	my $class = ref $self;
	if ($class !~ s/^${base}:://) {
		$class = "+$class";
	}

	if (!ref $to && $to !~ m{^\+|#|::}) {
		my $join = $class =~ m{#} ? '#' : '::';
		$to = join $join, $class, $to;
	}

	return $to;
}

sub request_body
{
	my ($self) = @_;

	# this is set by wrapper when there is request body validation
	return $self->context->req->stash->{request};
}

sub add_endpoint
{
	my ($self, $pattern, $args, %meta) = @_;

	# remove meta we don't want to be passed to the constructor and which are
	# not replaced by something else
	delete $meta{response_schemas};

	# make sure we have hash (same as in Kelp)
	$args = {
		to => $args,
	} unless ref $args eq 'HASH';

	# handle [METHOD => $pattern]
	if (ref $pattern eq 'ARRAY') {
		$args->{method} = $pattern->[0];
		$pattern = $pattern->[1];
	}

	$pattern = $self->_whelk_adjust_pattern($pattern);
	$args->{to} = $self->_whelk_adjust_to($args->{to});
	$args->{method} //= 'GET';
	my $route = $self->context->app->add_route($pattern, $args)->parent;
	$route->dest->[0] //= ref $self;    # makes sure plain subs work

	my $endpoint = Whelk::Endpoint->new(
		%meta,
		resource => $self->_whelk_config('resource'),
		formatter => $self->_whelk_config('formatter'),
		wrapper => $self->_whelk_config('wrapper'),
		route => $route,
	);

	push @{$self->context->app->whelk->endpoints}, $endpoint;
	return $self;
}

1;

__END__

=pod

=head1 NAME

Whelk::Role::Resource - Role for Whelk API resources

=head1 SYNOPSIS

	package My::Custom::Resource;

	use Kelp::Base 'My::Custom::Controller';
	use Role::Tiny::With;

	with qw(WhelK::Role::Resource);

	# required by the role
	sub api
	{
		my ($self) = @_;

		# implement the api
		...;
	}

=head1 DESCRIPTION

This is a role which implements Whelk resources. It must be applied to a Kelp
controller which is meant to be used as a resource for Whelk.
L<Whelk::Resource> is such controller, and is also a base controller for
L<Whelk> - there is no need to manually consume the role if you are extending
it. If you write your own Kelp application which uses Whelk, you most certainly
want to only apply it in a couple of your controllers and not the main
controller.

This role requires you to implement C<api> method - it will not apply if this
prerequisite is not met. It also requires C<context> attribute to be present,
which is also a requirement made by Kelp.

Whelk will reject any resources defined in its C<resources> configuration field
which do not consume this role.

=head1 METHODS

This role implements just a couple of helpful methods which you may use in
C<api> method and your route handler methods.

=head2 request_body

	my $body = $self->request_body;

A helper which returns the request body saved by the wrapper in stash key C<request>.

=head2 add_endpoint

Standard Whelk method to add endpoints, discussed at length in
L<Whelk::Manual/Adding endpoints>.

