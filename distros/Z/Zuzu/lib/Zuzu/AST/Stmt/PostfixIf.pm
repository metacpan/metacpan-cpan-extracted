package Zuzu::AST::Stmt::PostfixIf;

use utf8;

our $VERSION = '0.001003';

use Moo;

has 'statement' => ( is => 'rw' );
has 'cond' => ( is => 'rw' );
has 'negate' => ( is => 'rw', default => sub { 0 } );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_postfix_if($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::PostfixIf - AST node for postfix conditional statements

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and
delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 statement

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Wrapped statement that is conditionally executed.

=head2 cond

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Condition expression.

=head2 negate

Type: B<Bool>.

True when this node represents postfix C<unless>; false for postfix
C<if>.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::PostfixIf >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
