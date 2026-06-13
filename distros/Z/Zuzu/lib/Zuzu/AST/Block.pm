package Zuzu::AST::Block;

use utf8;

our $VERSION = '0.004000';

use Moo;

has 'statements' => ( is => 'rw' );
has 'reuse_current_env' => ( is => 'rw', default => sub { 0 } );

with 'Zuzu::AST::Role::Node';

sub evaluate {
	no warnings 'recursion';
	$_[1]->eval_block($_[0])
}

=pod

=head1 NAME

Zuzu::AST::Block - AST node representing a statement block

=head1 DESCRIPTION

AST container for a lexical block body that executes statements sequentially.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 statements

Type: B<ArrayRef[ConsumerOf["Zuzu::AST::Role::Node"]]>.

Ordered child statements contained in the node.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Block >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
