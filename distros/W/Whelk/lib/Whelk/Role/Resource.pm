package Whelk::Role::Resource;
$Whelk::Role::Resource::VERSION = '0.04';
use Kelp::Base -attr;
use Role::Tiny;

use Carp;

use Whelk::Endpoint;
use Whelk::Endpoint::Parameters;
use Whelk::Schema;

requires 'api';

sub _whelk_config
{
	my ($self, $key) = @_;

	return $self->whelk->resources->{ref $self}{$key};
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

	my $base = $self->routes->base;
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
	return $self->stash->{request};
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
	my $route = $self->add_route($pattern, $args)->parent;

	my $endpoint = Whelk::Endpoint->new(
		%meta,
		resource => $self->_whelk_config('resource'),
		formatter => $self->_whelk_config('formatter'),
		route => $route,
		code => $route->dest->[1],
	);

	$endpoint->wrap($self);

	push @{$self->whelk->endpoints}, $endpoint;
	return $self;
}

1;

