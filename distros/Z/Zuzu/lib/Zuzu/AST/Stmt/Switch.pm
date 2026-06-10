package Zuzu::AST::Stmt::Switch;

use utf8;

our $VERSION = '0.003000';

use Moo;

has 'value_expr' => ( is => 'rw' );
has 'comparator' => ( is => 'rw' );
has 'cases' => ( is => 'rw' );
has 'default_block' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_switch($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::Switch - AST node for switch statements

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and
delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 value_expr

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Expression that is compared against each case value.

=head2 comparator

Type: B<Str>.

Operator string used for case comparisons.

=head2 cases

Type: B<ArrayRef>.

Case definitions. Each item is a hashref containing C<values> and
C<body>.

=head2 default_block

Type: B<Maybe[InstanceOf["Zuzu::AST::Block"]]>.

Optional default case block.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Switch >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
