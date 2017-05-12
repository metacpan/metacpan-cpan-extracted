package Tie::BoundedInteger;
use strict;

use Carp qw(croak);

use vars qw( $VERSION );

$VERSION = '1.001';

sub TIESCALAR {
	my $class = shift;
	my $value = shift;
	my $max   = shift;

	my $self = bless [ 0, $max ], $class;

	$self->STORE( $value );

	return $self;
	}

sub FETCH { $_[0]->[0] }

sub STORE {
	my $self  = shift;
	my $value = shift;

	my $magnitude = abs $value;

	croak( "The [$value] exceeds the allowed limit [$self->[1]]" )
		if( int($value) != $value || $magnitude > $self->[1] );

	$self->[0] = $value;

	$value;
	}

1;

__END__

=head1 NAME

Tie::BoundedInteger - Limit the magnitude of a number in a scalar

=head1 SYNOPSIS

	use v5.10.1;
	use Tie::BoundedInteger;

	tie my $bounded, 'Tie::BoundedInteger', $min, $max;


=head1 DESCRIPTION

You use C<Tie::BoundedInteger> limits the magnitude of a scalar by
using the C<tie> mechanism.

=head1 SOURCE AVAILABILITY

This module is on Github:

	https://github.com/briandfoy/tie-boundedinteger

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2013, brian d foy, All rights reserved

This software is available under the same terms as perl.


