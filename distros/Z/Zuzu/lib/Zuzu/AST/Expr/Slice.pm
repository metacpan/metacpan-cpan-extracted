package Zuzu::AST::Expr::Slice;

use utf8;

our $VERSION = '0.002000';

use Moo;

has 'collection' => ( is => 'rw' );
has 'start' => ( is => 'rw' );
has 'length' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_slice($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::Slice - AST node for slice expressions

=head1 DESCRIPTION

Represents one expression form in the abstract syntax tree and delegates evaluation to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 collection

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Expression that yields the value being sliced.

=head2 start

Type: B<Maybe[ConsumerOf["Zuzu::AST::Role::Node"]]>.

Optional expression for the starting index.

=head2 length

Type: B<Maybe[ConsumerOf["Zuzu::AST::Role::Node"]]>.

Optional expression for the slice length.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::Slice >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
