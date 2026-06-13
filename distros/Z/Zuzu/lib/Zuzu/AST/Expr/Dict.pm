package Zuzu::AST::Expr::Dict;

use utf8;

our $VERSION = '0.004000';

use Moo;

has 'pairs' => ( is => 'rw' ); # [ [key_expr, val_expr], ... ]

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_dict($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::Dict - AST node for dict expressions

=head1 DESCRIPTION

Represents one expression form in the abstract syntax tree and delegates evaluation to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 pairs

Type: B<HashRef[ConsumerOf["Zuzu::AST::Role::Node"]]>.

Dictionary literal key/value expression map.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::Dict >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;