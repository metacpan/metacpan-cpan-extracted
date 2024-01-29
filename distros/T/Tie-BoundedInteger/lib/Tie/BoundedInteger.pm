package Tie::BoundedInteger;
use strict;

use Carp qw(croak);

our $VERSION = '1.073';

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

=encoding utf8

=head1 NAME

Tie::BoundedInteger - Limit the magnitude of a number in a scalar

=head1 SYNOPSIS

	use Tie::BoundedInteger;
	my( $min, $max ) = ( 1, 4 );
	tie my $bounded, 'Tie::BoundedInteger', $min, $max;

	$bounded = 3;  # works fine
	$bounded = 5;  # doesn't work


=head1 DESCRIPTION

You use C<Tie::BoundedInteger> limits the magnitude of a scalar by
using the C<tie> mechanism. This is mostly a demonstration module that
shows how C<tie> works.

=head1 SOURCE AVAILABILITY

This module is on Github:

	https://github.com/briandfoy/tie-boundedinteger

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2005-2024, brian d foy <bdfoy@cpan.org>. All rights reserved.
This software is available under the terms of the Artistic License 2.0.


