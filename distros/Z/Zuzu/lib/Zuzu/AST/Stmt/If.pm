package Zuzu::AST::Stmt::If;

use utf8;

our $VERSION = '0.005000';

use Moo;

has 'cond' => ( is => 'rw' );
has 'then_block' => ( is => 'rw' );
has 'else_branch' => ( is => 'rw' ); # else_branch: Block or If or undef

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_if($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::If - AST node for if statements

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

=head2 then_block

Type: B<InstanceOf["Zuzu::AST::Block"]>.

Block executed when C<cond> is truthy.

=head2 else_branch

Type: B<Maybe[InstanceOf["Zuzu::AST::Block"]]>.

Optional block executed when C<cond> is falsey.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::If >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;