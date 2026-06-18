package Zuzu::AST::Stmt::Die;

use utf8;

our $VERSION = '0.005000';

use Moo;

has 'expr' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_die($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::Die - AST node for die statements

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 expr

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Expression that evaluates to the thrown fatal value.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Die >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
