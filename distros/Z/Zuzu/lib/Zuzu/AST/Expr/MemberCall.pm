package Zuzu::AST::Expr::MemberCall;

use utf8;

our $VERSION = '0.001005';

use Moo;

has 'object' => ( is => 'rw' );
has 'method' => ( is => 'rw' );
has 'args' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate {
	no warnings 'recursion';
	$_[1]->eval_member_call($_[0]);
}

=pod

=head1 NAME

Zuzu::AST::Expr::MemberCall - AST node for membercall expressions

=head1 DESCRIPTION

Represents one expression form in the abstract syntax tree and delegates evaluation to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 object

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Expression whose member/index is being accessed.

=head2 method

Type: B<Any>.

Value stored in the C<method> attribute.

=head2 args

Type: B<ArrayRef[ConsumerOf["Zuzu::AST::Role::Node"]]>.

Ordered argument expressions for a call.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::MemberCall >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;