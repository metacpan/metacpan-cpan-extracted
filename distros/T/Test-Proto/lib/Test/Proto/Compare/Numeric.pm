package Test::Proto::Compare::Numeric;
use strict;
use warnings;
use Moo;
extends 'Test::Proto::Compare';

sub BUILDARGS {
	my $class = shift;
	return {
		summary => '<=>',
		code    => sub { $_[0] <=> $_[1] },
		( exists( $_[0] ) ? ( code => $_[0] ) : () )
	};
}

=head1 NAME

Test::Proto::Compare::Numeric - numeric comparison

=head1 SYNOPSIS

	my $c = Test::Proto::Compare::Numeric;
	$c->compare($left, $right); # $left <=> $right
	$c->reverse->compare($left, $right); # $right <=> $left

This class provides a wrapper for comparison functions so they can be identified by formatters. Except as described below, identical to L<Test::Proto::Compare>.

=head1 METHODS

=head3 code

Chainable attribute containing the code, which by default is a numeric comparison.


=head3 summary

Chainable attribute; a brief human-readable description of the operation which will be performed. Default is '<=>'.

=cut

1;
