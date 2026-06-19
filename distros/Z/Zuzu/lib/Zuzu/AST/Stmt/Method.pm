package Zuzu::AST::Stmt::Method;

use utf8;

our $VERSION = '0.006000';

use Moo;

has 'name' => ( is => 'rw' );
has 'params' => ( is => 'rw' );
has 'vararg' => ( is => 'rw' );
has 'named_vararg' => ( is => 'rw' );
has 'body' => ( is => 'rw' );
has 'is_static' => ( is => 'rw' );
has 'param_types' => ( is => 'rw', default => sub { {} } );
has 'vararg_type' => ( is => 'rw', default => sub { 'Any' } );
has 'named_vararg_type' => ( is => 'rw', default => sub { 'PairList' } );
has 'param_optional' => ( is => 'rw', default => sub { {} } );
has 'param_defaults' => ( is => 'rw', default => sub { {} } );
has 'return_type' => ( is => 'rw', default => sub { 'Any' } );
has 'is_async' => ( is => 'rw', default => sub { 0 } );
has 'uses_super' => ( is => 'rw', default => sub { undef } );
has 'is_predeclared' => ( is => 'rw', default => sub { 0 } );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_method_def($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::Method - AST node for method declarations

=head1 DESCRIPTION

Represents either an instance method or static method declaration
inside a class body.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 name

Type: B<Str>.

Identifier name declared or referenced by the node/value.

=head2 params

Type: B<ArrayRef[Str]>.

Ordered list of named function parameters.

=head2 vararg

Type: B<Maybe[Str]>.

Optional parameter name that receives trailing arguments.

=head2 body

Type: B<InstanceOf["Zuzu::AST::Block"]>.

Function or loop block executed by the node/value.

=head2 is_static

Type: B<Bool>.

Whether this method is invoked on the class instead of instances.

=head2 uses_super

Type: B<Maybe[Bool]>.

Whether this method uses C<super>. C<undef> means the method has not been
analysed yet.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Method >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
