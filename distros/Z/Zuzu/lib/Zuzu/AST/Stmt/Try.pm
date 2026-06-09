package Zuzu::AST::Stmt::Try;

use utf8;

our $VERSION = '0.002000';

use Moo;

has 'block' => ( is => 'rw' );
has 'catches' => ( is => 'rw', default => sub { [] } );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_try($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::Try - AST node for try/catch statements

=head1 DESCRIPTION

Represents one statement form in the abstract syntax tree and delegates execution to C<Zuzu::Runtime>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 block

Type: B<InstanceOf["Zuzu::AST::Block"]>.

Try block body that may throw and be caught by clauses.

=head2 catches

Type: B<ArrayRef[InstanceOf["Zuzu::AST::Stmt::Catch"]]>.

Ordered catch clauses that are tested left-to-right.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Try >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
