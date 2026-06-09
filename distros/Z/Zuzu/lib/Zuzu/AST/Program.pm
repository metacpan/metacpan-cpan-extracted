package Zuzu::AST::Program;

use utf8;

our $VERSION = '0.002000';

use Moo;

has 'statements' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_program($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Program - AST node representing an entire program

=head1 DESCRIPTION

Top-level AST container for a source file; holds program statements in order.

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

B<< Zuzu::AST::Program >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;