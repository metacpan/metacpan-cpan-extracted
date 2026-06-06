package Zuzu::AST::Expr::DynamicMemberCall;

use utf8;

our $VERSION = '0.001005';

use Moo;

has 'object' => ( is => 'rw' );
has 'method_expr' => ( is => 'rw' );
has 'args' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_dynamic_member_call($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::DynamicMemberCall - AST node for dynamic member calls

=head1 DESCRIPTION

Represents one expression form in the abstract syntax tree and delegates evaluation to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 object

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Expression that resolves to the target object.

=head2 method_expr

Type: B<ConsumerOf["Zuzu::AST::Role::Node"]>.

Expression whose string value names the member to call.

=head2 args

Type: B<ArrayRef[ConsumerOf["Zuzu::AST::Role::Node"]]>.

Positional argument expressions.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::DynamicMemberCall >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
