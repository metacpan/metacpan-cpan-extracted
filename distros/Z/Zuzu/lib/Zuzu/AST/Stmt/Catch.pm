package Zuzu::AST::Stmt::Catch;

use utf8;

our $VERSION = '0.007000';

use Moo;

has 'type_expr' => ( is => 'rw' );
has 'name' => ( is => 'rw' );
has 'block' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_catch($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::Catch - AST node for one catch clause

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 type_expr

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Type expression used to match thrown values.

=head2 name

Type: B<Str>.

Identifier bound in the catch block for the thrown value.

=head2 block

Type: B<InstanceOf["Zuzu::AST::Block"]>.

Block executed when this catch clause matches.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Catch >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
