package Zuzu::AST::Stmt::While;

use utf8;

our $VERSION = '0.006000';

use Moo;

has 'cond' => ( is => 'rw' );
has 'body' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_while($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::While - AST node for while statements

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 cond

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Condition expression controlling branch/loop flow.

=head2 body

Type: B<InstanceOf["Zuzu::AST::Block"]>.

Function or loop block executed by the node/value.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::While >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;