package Zuzu::AST::Expr::Binary;

use utf8;

our $VERSION = '0.001002';

use Moo;

has 'op' => ( is => 'rw' );
has 'left' => ( is => 'rw' );
has 'right' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_binary($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::Binary - AST node for binary expressions

=head1 DESCRIPTION

Represents one expression form in the abstract syntax tree and delegates evaluation to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 op

Type: B<Str>.

Operator symbol used by this AST node.

=head2 left

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Left operand expression.

=head2 right

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Right operand expression.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::Binary >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;