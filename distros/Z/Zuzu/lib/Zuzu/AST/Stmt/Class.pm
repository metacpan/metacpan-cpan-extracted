package Zuzu::AST::Stmt::Class;

use utf8;

our $VERSION = '0.003000';

use Moo;

has 'name' => ( is => 'rw' );
has 'parent' => ( is => 'rw' );
has 'traits' => ( is => 'rw' );
has 'fields' => ( is => 'rw' );
has 'methods' => ( is => 'rw' );
has 'static_methods' => ( is => 'rw' );
has 'classes' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_class_def($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::Class - AST node for class statements

=head1 DESCRIPTION

Represents a class declaration with optional inheritance, fields,
methods, and nested classes.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 name

Type: B<Str>.

Identifier name declared or referenced by the node/value.

=head2 parent

Type: B<Maybe[InstanceOf["Zuzu::AST::Expr::TypeRef"]]>.

Optional parent class name used for inheritance lookup.

=head2 traits

Type: B<ArrayRef[InstanceOf["Zuzu::AST::Expr::TypeRef"]]>.

Trait references mixed into this class via C<with> or C<but>.

=head2 fields

Type: B<ArrayRef[HashRef]>.

Ordered field declarations with C<name>, C<is_const>, and C<init>.

=head2 methods

Type: B<ArrayRef[InstanceOf["Zuzu::AST::Stmt::Method"]]>.

Instance methods declared in this class.

=head2 static_methods

Type: B<ArrayRef[InstanceOf["Zuzu::AST::Stmt::Method"]]>.

Static methods declared in this class.

=head2 classes

Type: B<ArrayRef[InstanceOf["Zuzu::AST::Stmt::Class"]]>.

Nested class declarations scoped within this class.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Class >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
