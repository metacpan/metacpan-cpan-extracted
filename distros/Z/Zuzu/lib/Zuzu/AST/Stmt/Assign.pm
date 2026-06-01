package Zuzu::AST::Stmt::Assign;

use utf8;

our $VERSION = '0.001003';

use Moo;

has 'target' => ( is => 'rw' );
has 'op' => ( is => 'rw' );
has 'expr' => ( is => 'rw' );
has 'match_expr' => ( is => 'rw' );
has 'replace_expr' => ( is => 'rw' );
has 'is_weak_write' => ( is => 'rw', default => sub { 0 } );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_assign($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::Assign - AST node for assign statements

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 target

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Assignment target expression (usually a variable).

=head2 op

Type: B<Str>.

Operator symbol used by this AST node.

=head2 expr

Type: B<Maybe[ConsumerOf["Zuzu::AST::Role::Node"]]>.

Expression child evaluated by this node.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Assign >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
