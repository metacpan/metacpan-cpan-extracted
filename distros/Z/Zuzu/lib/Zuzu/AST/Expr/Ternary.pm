package Zuzu::AST::Expr::Ternary;

use utf8;

our $VERSION = '0.002000';

use Moo;

has 'cond' => ( is => 'rw' );
has 'if_true' => ( is => 'rw' );
has 'if_false' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_ternary($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::Ternary - AST node for ternary expressions

=head1 DESCRIPTION

Represents one expression form in the abstract syntax tree and
delegates evaluation to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 cond

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Condition expression.

=head2 if_true

Type: B<Maybe[ConsumerOf["Zuzu::AST::Role::Node"]]>.

Expression evaluated when C<cond> is truthy. May be absent for the
abbreviated ternary form C<?:>.

=head2 if_false

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Expression evaluated when C<cond> is falsey.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::Ternary >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
