package Zuzu::AST::Stmt::For;

use utf8;

our $VERSION = '0.001002';

use Moo;

has 'var' => ( is => 'rw' );
has 'declare_loop_var' => ( is => 'rw', default => sub { 1 } );
has 'loop_var_kind' => ( is => 'rw' );
has 'collection' => ( is => 'rw' );
has 'body' => ( is => 'rw' );
has 'else_block' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_for($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::For - AST node for for statements

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 var

Type: B<Str>.

Loop variable name bound for each iteration.

=head2 collection

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Expression producing the iterable collection for the loop.

=head2 body

Type: B<InstanceOf["Zuzu::AST::Block"]>.

Function or loop block executed by the node/value.

=head2 declare_loop_var

Type: B<Bool>.

When true, the loop header declared the iteration variable with C<let>
or C<const>.
When false, the loop reuses an already declared variable.

=head2 loop_var_kind

Type: B<Maybe[Str]>.

Declaration keyword used for the loop variable when
C<declare_loop_var> is true. Expected values are C<let> or C<const>.

=head2 else_block

Type: B<Maybe[InstanceOf["Zuzu::AST::Block"]]>.

Optional block executed when a loop has zero iterations.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::For >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
