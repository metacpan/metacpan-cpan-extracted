package Zuzu::AST::Expr::TypeRef;

use utf8;

our $VERSION = '0.007001';

use Moo;

has 'root' => ( is => 'rw' );
has 'member' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_type_ref($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::TypeRef - AST node for type reference expressions

=head1 DESCRIPTION

Represents a type expression used in class inheritance and trait
composition, including imported names like C<mod{TypeName}>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 root

Type: B<Str>.

Base identifier of the referenced type value.

=head2 member

Type: B<Maybe[Str]>.

Optional member name for dictionary-style type references.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::TypeRef >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
