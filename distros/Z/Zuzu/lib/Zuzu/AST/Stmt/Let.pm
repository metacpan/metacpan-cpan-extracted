package Zuzu::AST::Stmt::Let;

use utf8;

our $VERSION = '0.001003';

use Moo;

has 'name' => ( is => 'rw' );
has 'init' => ( is => 'rw' );
has 'is_const' => ( is => 'rw' );
has 'declared_type' => ( is => 'rw', default => sub { 'Any' } );
has 'is_weak_storage' => ( is => 'rw', default => sub { 0 } );

with 'Zuzu::AST::Role::Node';

sub evaluate {
	no warnings 'recursion';
	$_[1]->eval_let($_[0])
}

=pod

=head1 NAME

Zuzu::AST::Stmt::Let - AST node for let statements

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 name

Type: B<Str>.

Identifier name declared or referenced by the node/value.

=head2 init

Type: B<Maybe[ConsumerOf["Zuzu::AST::Role::Node"]]>.

Initializer expression for declarations, if present.

=head2 is_const

Type: B<Bool>.

True when the declared binding is immutable.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Let >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
