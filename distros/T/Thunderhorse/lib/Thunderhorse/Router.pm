package Thunderhorse::Router;
$Thunderhorse::Router::VERSION = '0.102';
use v5.40;
use Mooish::Base -standard;

use Thunderhorse::Router::Location;
use Gears::X::Thunderhorse;

extends 'Gears::Router';

has field 'controller' => (
	isa => InstanceOf ['Thunderhorse::Controller'],
	writer => 1,
);

# external caches should have a L1 cache in front of it to map location names
# to location objects
has option 'cache' => (
	isa => HasMethods ['get', 'set', 'clear'],
	writer => 1,
	trigger => 1,
);

has field '_registered' => (
	isa => HashRef,
	default => sub { {} },
);

# id of the last route. All route building must be in deterministic order, so
# that multiple forked processes can use the same external cached table
has field '_last_route_id' => (
	isa => PositiveOrZeroInt,
	default => 0,
	writer => 1,
);

sub _trigger_cache ($self, $new)
{
	if ($new->DOES('Thunderhorse::Router::SpecializedCache')) {
		$new->set_router($self);
	}
}

sub _build_location ($self, %args)
{
	return Thunderhorse::Router::Location->new(
		%args,
		controller => $self->controller,
	);
}

sub _match_level ($self, $locations, @args)
{
	my @result = $self->SUPER::_match_level($locations, @args);

	# optimization - very common to have just one match on a single level
	return @result unless @result > 1;

	return
		map { $_->[0] }
		sort { $a->[1] <=> $b->[1] }
		map { [$_, (ref eq 'ARRAY' ? $_->[0] : $_)->location->order] }
		@result;
}

sub _maybe_cache ($self, $type, $path, $method)
{
	return $self->$type($path, $method)
		unless $self->has_cache;

	my $key = "$type;$method;$path";
	my $result = $self->cache->get($key);
	return $result->@* if $result;

	$result = [$self->$type($path, $method)];
	$self->cache->set($key, $result);
	return $result->@*;
}

sub match ($self, $path, $method //= '')
{
	return ($self->_maybe_cache('SUPER::match', $path, $method))[0];
}

sub flat_match ($self, $path, $method //= '')
{
	return $self->_maybe_cache('SUPER::flat_match', $path, $method);
}

sub clear ($self)
{
	$self->cache->clear
		if $self->has_cache;

	$self->_registered->%* = ();

	return $self->SUPER::clear;
}

sub _get_next_route_id ($self)
{
	my $last = $self->_last_route_id;
	$self->_set_last_route_id(++$last);

	return $last;
}

sub _register_location ($self, $name, $location)
{
	Gears::X::Thunderhorse->raise("duplicate location $name - location names must be unique")
		if $self->_registered->{$name};

	$self->_registered->{$name} = $location;
}

sub find ($self, $name)
{
	return $self->_registered->{$name};
}

__END__

=head1 NAME

Thunderhorse::Router - Router for Thunderhorse

=head1 SYNOPSIS

	my $router_obj = $app->router;

=head1 DESCRIPTION

Thunderhorse router is a class which allows adding new locations (using
L<Gears::Router/add>), finding locations (using L</find>) and matching them
(using L<Gears::Router/match>). It uses L<Thunderhorse::Router::Location> as
the location implementation.

=head1 INTERFACE

Inherits all interface from L<Gears::Router>, and adds the interface
documented below.

=head2 Attributes

=head3 controller

Current controller. It is set automatically when calling the C<router> method
in an app or in a controller. All locations built will use this attribute as
their controller.

B<writer:> C<set_controller>

=head3 cache

Cache object - must have at least C<get>, C<set> and C<clear> methods. If
specified, all matching will be cached in that object. For best results,
C<Thunderhorse::Router::SpecializedCache> role should be mixed into the cache.
This role makes sure that L<Gears::Router::Match/location> will be stored as a
location name in cache, not as a full L<Gears::Router::Location> object. This
way less data will be held in the cache, and if the cache is stored outside of
perl memory, it will be easily mapped in a way that allows multiple servers
workers to use the same cached values.

I<Available in constructor>

B<writer:> C<set_cache>

=head2 Methods

=head3 new

	$object = $class->new(%args)

Standard Mooish constructor. Consult L</Attributes> section for available
constructor arguments.

=head3 find

	$location = $object->find($name)

Returns the location with the given C<$name>. If no such location exists,
returns C<undef>.

=head1 SEE ALSO

L<Gears::Router>

