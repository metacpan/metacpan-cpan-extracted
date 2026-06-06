package Zuzu::AST::Stmt::Trait;

use utf8;

our $VERSION = '0.001005';

use Moo;

has 'name' => ( is => 'rw' );
has 'methods' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_trait_def($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Stmt::Trait - AST node for trait declarations

=head1 DESCRIPTION

Represents a trait declaration, including the trait's method
definitions.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

Consumes C<Zuzu::AST::Role::Node>.

=head1 ATTRIBUTES

=head2 name

Type: B<Str>.

Identifier name declared or referenced by the node/value.

=head2 methods

Type: B<ArrayRef[InstanceOf["Zuzu::AST::Stmt::Method"]]>.

Instance methods contributed by this trait.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head1 SEE ALSO

C<Zuzu::AST::Role::Node>.

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Stmt::Trait >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
