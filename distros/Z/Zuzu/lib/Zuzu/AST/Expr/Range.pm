package Zuzu::AST::Expr::Range;

use utf8;

our $VERSION = '0.001000';

use Moo;

has 'start' => ( is => 'rw' );
has 'end' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate { $_[1]->eval_range($_[0]) }

=pod

=head1 NAME

Zuzu::AST::Expr::Range - AST node for inclusive integer ranges

=head1 DESCRIPTION

Represents an inclusive integer range expression used inside array
literals, for example C<[ 1...5 ]> or C<[ 5...1 ]>.

=head1 ATTRIBUTES

=head2 start

Type: expression node.

The expression that provides the first value in the range.

=head2 end

Type: expression node.

The expression that provides the last value in the range.

=head1 METHODS

=head2 evaluate

Dispatches this AST node to C<Zuzu::Runtime::eval_range>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::Range >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
