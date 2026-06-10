package Zuzu::Value::Object;

use utf8;

our $VERSION = '0.003000';

use Moo;

has 'class' => ( is => 'rw' );
has 'slots' => ( is => 'rw' );
has 'const' => ( is => 'rw' );
has 'types' => ( is => 'rw', default => sub { {} } );
has 'weak' => ( is => 'rw', default => sub { {} } );
has 'demolish_hook' => ( is => 'rw' );

sub is_truthy { 1 }

sub run_demolish_hook {
	my ( $self ) = @_;

	my $hook = $self->demolish_hook;
	return if ref($hook) ne 'CODE';
	$self->demolish_hook(undef);

	local $@;
	eval { $hook->($self); 1 } or return;

	return;
}

sub DESTROY {
	my ( $self ) = @_;

	$self->run_demolish_hook;

	return;
}

=pod

=head1 NAME

Zuzu::Value::Object - runtime value class for class instances

=head1 DESCRIPTION

Represents an instantiated object with class reference and slot
storage.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 class

Type: B<InstanceOf["Zuzu::Value::Class"]>.

Class value used for method dispatch and inheritance checks.

=head2 slots

Type: B<HashRef>.

Storage for instance members and class constants copied to object.

=head2 const

Type: B<HashRef[Bool]>.

Per-slot const flags enforcing assignment restrictions.

=head1 METHODS

=head2 is_truthy

Returns this runtime value's truthiness in ZuzuScript.

=head2 run_demolish_hook

Runs and clears the optional lifecycle cleanup callback.

=head2 DESTROY

Runs the optional lifecycle cleanup callback before this object is
garbage collected.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Object >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
