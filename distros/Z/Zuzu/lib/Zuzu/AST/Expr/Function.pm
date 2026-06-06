package Zuzu::AST::Expr::Function;

use utf8;

our $VERSION = '0.001005';

use Moo;

has 'params' => ( is => 'rw' );
has 'vararg' => ( is => 'rw' );
has 'named_vararg' => ( is => 'rw' );
has 'body' => ( is => 'rw' );
has 'param_types' => ( is => 'rw', default => sub { {} } );
has 'vararg_type' => ( is => 'rw', default => sub { 'Any' } );
has 'named_vararg_type' => ( is => 'rw', default => sub { 'PairList' } );
has 'param_optional' => ( is => 'rw', default => sub { {} } );
has 'param_defaults' => ( is => 'rw', default => sub { {} } );
has 'return_type' => ( is => 'rw', default => sub { 'Any' } );
has 'is_async' => ( is => 'rw', default => sub { 0 } );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_function_expr($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::Function - AST node for function expression values

=head1 DESCRIPTION

Represents an anonymous or lambda-style function expression in the AST
and delegates evaluation to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 params

Type: B<ArrayRef[Str]>.

Ordered list of named function parameters.

=head2 vararg

Type: B<Maybe[Str]>.

Optional parameter name that receives trailing arguments.

=head2 body

Type: B<InstanceOf["Zuzu::AST::Block"]>.

Function body block executed by this expression when called.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::Function >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
