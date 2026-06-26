package Zuzu::AST::Expr::New;

use utf8;

our $VERSION = '0.007000';

use Moo;

has 'class_expr' => ( is => 'rw' );
has 'traits' => ( is => 'rw' );
has 'args' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_new($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::New - AST node for object construction expressions

=head1 DESCRIPTION

Represents a C<new ClassName(...)> expression with named
constructor arguments.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 class_expr

Type: B<Zuzu::AST::Role::Node>.

Expression that resolves to the class value being instantiated.

=head2 traits

Type: B<ArrayRef[Zuzu::AST::Role::Node]>.

Optional trait references to compose for this one constructed object.

=head2 args

Type: B<ArrayRef[ArrayRef]>.

Ordered constructor named arguments as C<[ key, expr ]> pairs.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::New >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
