package Zuzu::AST::Expr::Spread;

use utf8;

our $VERSION = '0.001003';

use Moo;
use Zuzu::Error;

has 'expr' => ( is => 'rw' );

with 'Zuzu::AST::Role::Node';

sub evaluate {
	my ( $self ) = @_;

	die Zuzu::Error->new_runtime(
		message => "Spread argument expansion is not implemented yet",
		file => $self->file,
		line => $self->line,
	);
}

=pod

=head1 NAME

Zuzu::AST::Expr::Spread - AST marker for call argument spreading

=head1 DESCRIPTION

Represents C<...expr> in a call argument list. Runtime expansion is not
implemented in this phase.

=head1 ATTRIBUTES

=head2 expr

The expression that will provide values to spread.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Expr::Spread >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
