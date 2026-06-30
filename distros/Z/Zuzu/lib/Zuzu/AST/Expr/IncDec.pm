package Zuzu::AST::Expr::IncDec;

use utf8;

our $VERSION = '0.007001';

use Moo;

has 'op' => ( is => 'rw' );
has 'target' => ( is => 'rw' );
has 'postfix' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_incdec($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::IncDec - AST node for increment/decrement expressions

=head1 DESCRIPTION

Represents one expression form in the abstract syntax tree and
delegates evaluation to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 op

Type: B<Str>.

Operator symbol, either C<++> or C<-->.

=head2 target

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Lvalue target expression to mutate.

=head2 postfix

Type: B<Bool>.

True for postfix form (C<x++> / C<x-->), false for prefix form
(C<++x> / C<--x>).

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::IncDec >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
