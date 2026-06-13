package Zuzu::Env;

use utf8;

our $VERSION = '0.004000';

use Moo;

has 'parent' => ( is => 'rw' );
has 'slots' => ( is => 'rw', default => sub { {} } );
has 'const' => ( is => 'rw', default => sub { {} } );
has 'types' => ( is => 'rw', default => sub { {} } );
has 'weak' => ( is => 'rw', default => sub { {} } );
has 'special_props' => ( is => 'rw', default => sub { {} } );

sub _new_fast {
	my ( $class, $parent ) = @_;

	return bless {
		parent        => $parent,
		slots         => {},
		const         => {},
		types         => {},
		weak          => {},
		special_props => {},
	}, $class;
}

sub declare {
	my (
		$self, $name, $value, $is_const,
		$declared_type, $is_weak_storage,
	) = @_;

	die "Internal redeclare $name" if exists $self->{slots}{$name};
	$self->{slots}{$name} = \$value;        # aliasing by reference
	$self->{const}{$name} = $is_const ? 1 : 0;
	$self->{types}{$name} = $declared_type // 'Any';
	$self->{weak}{$name} = $is_weak_storage ? 1 : 0;

	return $self->{slots}{$name};
}

sub alias_to_ref {
	my (
		$self, $name, $ref, $is_const,
		$declared_type, $is_weak_storage,
	) = @_;

	$self->{slots}{$name} = $ref;
	$self->{const}{$name} = $is_const ? 1 : 0;
	$self->{types}{$name} = $declared_type // 'Any';
	$self->{weak}{$name} = $is_weak_storage ? 1 : 0;

	return $ref;
}

sub find_ref {
	my ($self, $name) = @_;

	my $env = $self;
	while ($env) {
		return $env->{slots}{$name} if exists $env->{slots}{$name};
		$env = $env->{parent};
	}

	return undef;
}

sub is_const_here {
	my ($self, $name) = @_;

	no warnings 'uninitialized';
	return $self->{const}{$name} if exists $self->{const}{$name};

	return undef;
}

sub is_weak_here {
	my ($self, $name) = @_;

	no warnings 'uninitialized';
	return $self->{weak}{$name} if exists $self->{weak}{$name};

	return undef;
}

sub is_weak_slot {
	my ($self, $name) = @_;

	my $env = $self;
	while ($env) {
		return $env->{weak}{$name} if exists $env->{weak}{$name};
		$env = $env->{parent};
	}

	return 0;
}

sub set_weak_slot {
	my ( $self, $name, $is_weak_storage ) = @_;

	if ( exists $self->{slots}{$name} ) {
		$self->{weak}{$name} = $is_weak_storage ? 1 : 0;
		return $self->{weak}{$name};
	}

	return $self->{parent}->set_weak_slot( $name, $is_weak_storage )
		if $self->{parent};

	return undef;
}

sub declared_type_for {
	my ( $self, $name ) = @_;

	my $env = $self;
	while ($env) {
		return $env->{types}{$name} if exists $env->{types}{$name};
		$env = $env->{parent};
	}

	return 'Any';
}

sub get_special_prop {
	my ( $self, $key ) = @_;

	return $self->{special_props}{$key}
		if exists $self->{special_props}{$key};
	return $self->{parent}->get_special_prop( $key )
		if $self->{parent};

	return undef;
}

sub set_special_prop {
	my ( $self, $key, $value ) = @_;

	$self->{special_props}{$key} = $value;
	return $value;
}

=pod

=head1 NAME

Zuzu::Env - lexical environment used for variable bindings

=head1 DESCRIPTION

Stores lexical bindings as references, tracks const-ness, and resolves
names through parent scopes.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 parent

Type: B<Maybe[InstanceOf["Zuzu::Env"]]>.

Enclosing lexical scope, or undef for the global scope.

=head2 slots

Type: B<HashRef[ScalarRef]>.

Variable storage map from names to scalar references.

=head2 const

Type: B<HashRef[Bool]>.

Const-ness map; true entries cannot be reassigned.

=head2 weak

Type: B<HashRef[Bool]>.

Weak-storage map; true entries store weakable values as weak references.

=head1 METHODS

=head2 new

Constructs and returns a new instance of this class.

=head2 declare

Declares a new name in the current environment.

=head2 alias_to_ref

Binds a name to an existing scalar reference.

=head2 find_ref

Finds a variable reference in current or parent scopes.

=head2 is_const_here

Reports whether a locally-declared name is const.

=head2 is_weak_here

Reports whether a locally-declared name uses weak storage.

=head2 is_weak_slot

Reports whether a name uses weak storage, resolving through parent
scopes.

=head2 set_weak_slot

Updates the weak-storage flag for an existing name.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Env >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
