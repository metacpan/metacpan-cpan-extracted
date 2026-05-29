package Zuzu::Value::Class;

use utf8;

our $VERSION = '0.001000';

use Moo;

has 'name' => ( is => 'rw' );
has 'parent' => ( is => 'rw' );
has 'traits' => ( is => 'rw' );
has 'field_specs' => ( is => 'rw' );
has 'methods' => ( is => 'rw' );
has 'trait_methods' => ( is => 'rw' );
has 'static_methods' => ( is => 'rw' );
has 'nested_classes' => ( is => 'rw' );
has 'closure_env' => ( is => 'rw' );
has 'native_constructor' => ( is => 'rw' );
has 'builtin_kind' => ( is => 'rw' );
has 'source_node' => ( is => 'rw' );

sub is_truthy { 1 }

=pod

=head1 NAME

Zuzu::Value::Class - runtime value class for class values

=head1 DESCRIPTION

Represents class metadata needed for instantiation, inheritance,
and static dispatch.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 name

Type: B<Str>.

Identifier name declared or referenced by the node/value.

=head2 parent

Type: B<Maybe[InstanceOf["Zuzu::Value::Class"]]>.

Optional parent class used for inheritance lookups.

=head2 traits

Type: B<ArrayRef[InstanceOf["Zuzu::Value::Trait"]]>.

Trait values composed into this class.

=head2 field_specs

Type: B<ArrayRef[HashRef]>.

Field declaration metadata inherited during object creation.

=head2 methods

Type: B<HashRef[InstanceOf["Zuzu::Value::Function"]]>.

Instance method table for this class.

=head2 trait_methods

Type: B<HashRef[ArrayRef[InstanceOf["Zuzu::Value::Function"]]]>.

Trait-provided instance methods grouped by method name and preserved
in trait composition order.

=head2 static_methods

Type: B<HashRef[InstanceOf["Zuzu::Value::Function"]]>.

Static method table for this class.

=head2 nested_classes

Type: B<HashRef[InstanceOf["Zuzu::Value::Class"]]>.

Nested class table scoped beneath this class.

=head2 closure_env

Type: B<Maybe[InstanceOf["Zuzu::Env"]]>.

Lexical environment captured when the class is declared.

=head2 source_node

Type: B<Maybe[InstanceOf["Zuzu::AST::Stmt::Class"]]>.

Original class declaration AST, retained for source extraction.

=head1 METHODS

=head2 is_truthy

Returns this runtime value's truthiness in ZuzuScript.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Class >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
