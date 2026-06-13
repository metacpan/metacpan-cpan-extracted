package Zuzu::AST::Visitor::SuperHints;

use utf8;

our $VERSION = '0.004000';

use Scalar::Util qw( blessed refaddr );

use Moo;

sub apply {
	my ( $self, $ast ) = @_;

	$self->_visit_node($ast);

	return $ast;
}

sub _node_references_super {
	my ( $self, $node, $seen ) = @_;

	return 0 if !defined $node;
	$seen //= {};

	if ( blessed($node) ) {
		my $addr = refaddr($node);
		return 0 if defined $addr and $seen->{$addr}++;
		return 1
			if $node->isa('Zuzu::AST::Expr::Var')
			and $node->name eq 'super';

		for my $value ( values %{ $node } ) {
			return 1 if $self->_node_references_super( $value, $seen );
		}

		return 0;
	}

	if ( ref($node) eq 'ARRAY' ) {
		my $addr = refaddr($node);
		return 0 if defined $addr and $seen->{$addr}++;
		for my $value ( @{ $node } ) {
			return 1 if $self->_node_references_super( $value, $seen );
		}
		return 0;
	}

	if ( ref($node) eq 'HASH' ) {
		my $addr = refaddr($node);
		return 0 if defined $addr and $seen->{$addr}++;
		for my $value ( values %{ $node } ) {
			return 1 if $self->_node_references_super( $value, $seen );
		}
		return 0;
	}

	return 0;
}

sub _visit_node {
	my ( $self, $node, $seen ) = @_;

	return if !defined $node;
	$seen //= {};

	if ( blessed($node) ) {
		my $addr = refaddr($node);
		return if defined $addr and $seen->{$addr}++;

		if ( $node->isa('Zuzu::AST::Stmt::Method') ) {
			$node->uses_super( $self->_node_references_super($node) ? 1 : 0 );
		}

		for my $value ( values %{ $node } ) {
			$self->_visit_node( $value, $seen );
		}
		return;
	}

	if ( ref($node) eq 'ARRAY' ) {
		my $addr = refaddr($node);
		return if defined $addr and $seen->{$addr}++;
		for my $value ( @{ $node } ) {
			$self->_visit_node( $value, $seen );
		}
		return;
	}

	if ( ref($node) eq 'HASH' ) {
		my $addr = refaddr($node);
		return if defined $addr and $seen->{$addr}++;
		for my $value ( values %{ $node } ) {
			$self->_visit_node( $value, $seen );
		}
		return;
	}

	return;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Visitor::SuperHints >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
