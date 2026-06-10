package Zuzu::AST::Stmt::Import;

use utf8;

our $VERSION = '0.003000';

use Moo;

has 'module' => ( is => 'rw' );
has 'items' => ( is => 'rw' ); # items: [ {name=>, alias=>} ] or [ {star=>1} ]
has 'try_mode' => ( is => 'rw', default => sub { 0 } );
has 'condition_expr' => ( is => 'rw' );
has 'condition_positive' => ( is => 'rw', default => sub { 1 } );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_import($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::Import - AST node for import statements

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 module

Type: B<Any>.

Value stored in the C<module> attribute.

=head2 items

Type: B<ArrayRef>.

Ordered array elements (expressions or runtime values).

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Import >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
