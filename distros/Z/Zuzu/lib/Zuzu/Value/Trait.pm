package Zuzu::Value::Trait;

use utf8;

our $VERSION = '0.001002';

use Moo;

has 'name' => ( is => 'rw' );
has 'methods' => ( is => 'rw' );
has 'closure_env' => ( is => 'rw' );
has 'source_node' => ( is => 'rw' );

sub is_truthy { 1 }

=pod

=head1 NAME

Zuzu::Value::Trait - runtime value class for trait values

=head1 DESCRIPTION

Represents trait metadata and method definitions used for class
composition.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 name

Type: B<Str>.

Identifier name declared or referenced by the node/value.

=head2 methods

Type: B<HashRef[InstanceOf["Zuzu::Value::Function"]]>.

Method table provided by this trait.

=head2 closure_env

Type: B<Maybe[InstanceOf["Zuzu::Env"]]>.

Lexical environment captured when the trait is declared.

=head2 source_node

Type: B<Maybe[InstanceOf["Zuzu::AST::Stmt::Trait"]]>.

Original trait declaration AST, retained for source extraction.

=head1 METHODS

=head2 is_truthy

Returns this runtime value's truthiness in ZuzuScript.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Trait >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
