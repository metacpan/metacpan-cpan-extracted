use 5.008;
use strict;
use warnings;

package Tie::Moose;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Types::Standard -types;

with 'MooseX::Traits';

has object => (
	is       => 'ro',
	isa      => Object,
	required => 1,
);

has attributes => (
	is       => 'ro',
	isa      => ArrayRef[ ArrayRef[ Maybe[Str] ] ],
	lazy     => 1,
	builder  => '_build_attributes',
);

has attributes_hash => (
	is       => 'ro',
	isa      => HashRef[ ArrayRef[ Maybe[Str] ] ],
	lazy     => 1,
	builder  => '_build_attributes_hash',
);

has "+_trait_namespace" => (
	default  => __PACKAGE__,
);

sub _build_attributes
{
	return [
		map [
			$_->name,                   # 0
			$_->reader || $_->accessor, # 1
			$_->writer || $_->accessor, # 2
			$_->predicate,              # 3
			$_->clearer,                # 4
		], Class::MOP::class_of(shift->object)->get_all_attributes
	]
}

sub _build_attributes_hash
{
	return +{ map {; $_->[0], $_ } @{ shift->attributes } };
}

sub fallback
{
	my $self = shift;
	my ($operation, $key) = @_;
	croak "No attribute '$key' in tied object";
}

sub TIEHASH
{
	my $class = shift;
	my ($object, %opts) = @_;
	$class->new(%opts, object => $object);
}

sub FETCH
{
	my $self = shift;
	my ($key) = @_;
	
	$self->attributes_hash->{$key}
		or return $self->fallback(FETCH => $key);
	
	my $accessor = $self->attributes_hash->{$key}[1]
		or croak "No reader for attribute '$key' in tied object";
	return $self->object->$accessor;
}

sub STORE
{
	my $self = shift;
	my ($key, $value) = @_;
	
	$self->attributes_hash->{$key}
		or return $self->fallback(STORE => $key, $value);
	
	my $accessor = $self->attributes_hash->{$key}[2]
		or croak "No writer for attribute '$key' in tied object";
	return $self->object->$accessor($value);
}

sub EXISTS
{
	my $self = shift;
	my ($key) = @_;
	
	$self->attributes_hash->{$key}
		or return $self->fallback(EXISTS => $key);
	
	my $accessor = $self->attributes_hash->{$key}[3];
	$accessor and return $self->object->$accessor;
	
	return $self->object->meta->find_attribute_by_name($key)->has_value($self->object);
}

sub DELETE
{
	my $self = shift;
	my ($key) = @_;
	
	$self->attributes_hash->{$key}
		or return $self->fallback(DELETE => $key);
	
	my $accessor = $self->attributes_hash->{$key}[4]
		or croak "No clearer for attribute '$key' in tied object";
	return $self->object->$accessor;
}

sub CLEAR
{
	my $self = shift;
	
	for my $attr (@{$self->attributes})
	{
		my $name = $attr->[0];
		$self->EXISTS($name) and $self->DELETE($name);
	}
}

sub FIRSTKEY
{
	my $self = shift;
	for my $attr (@{$self->attributes})
	{
		next unless $self->EXISTS($attr->[0]);
		return $attr->[0];
	}
	return;
}

sub NEXTKEY
{
	my $self = shift;
	my ($lastkey) = @_;
	my $should_return;
	for my $attr (@{$self->attributes})
	{
		if ($attr->[0] eq $lastkey)
			{ $should_return++; }
		elsif (not $self->EXISTS($attr->[0]))
			{ next; }
		elsif ($should_return)
			{ return $attr->[0]; }
	}
	return;
}

sub SCALAR
{
	shift->object;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Tie::Moose - tie a hash to a Moose object (yeah, like Tie::MooseObject)

=head1 SYNOPSIS

	use v5.14;
	
	package Person {
		use Moose;
		has name => (
			is     => "rw",
			isa    => "Str",
		);
		has age => (
			is     => "rw",
			isa    => "Num",
			reader => "get_age",
			writer => "set_age",
		);
	}
	
	my $bob = Person->new(name => "Robert");
	
	tie my %bob, "Tie::Moose", $bob;
	
	$bob{age} = 32;       # calls the "set_age" method
	$bob{age} = "x";      # would croak
	$bob{xyz} = "x";      # would croak

=head1 DESCRIPTION

This module is much like L<Tie::MooseObject>. It ties a hash to an instance
of a L<Moose>-based class, allowing you to access attributes as hash keys. It
uses the accessors provided by Moose, and thus honours read-only attributes,
type constraints and coercions, triggers, etc.

There are a few key differences with L<Tie::MooseObject>:

=over

=item *

It handles differently named getters/setters more to my liking. Given the
example in the SYNOPSIS, with Tie::MooseObject you need to write:

	$bob{set_age} = 32;
	say $bob{get_age};

Whereas with Tie::Moose, you just use the C<age> hash key for both fetching
from and storing to the hash.

=item *

Implements C<DELETE> from the L<Tie::Hash> interface. Tie::MooseObject does
not allow keys to be deleted from its hashes.

(C<DELETE> only works on Moose attributes that have a "clearer" method.)

=item *

Supplied with various traits to influence the behaviour of the tied hash.

	tie my %bob, "Tie::Moose"->with_traits("ReadOnly"), $bob;

(Note that by design, many of the traits supplied with Tie::Moose are
mutually exclusive.)

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Tie-Moose>.

=head1 SEE ALSO

L<Tie::MooseObject>.

Traits for Tie::Moose hashes:
L<Tie::Moose::ReadOnly>,
L<Tie::Moose::Forgiving>,
L<Tie::Moose::FallbackHash>,
L<Tie::Moose::FallbackSlot>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

