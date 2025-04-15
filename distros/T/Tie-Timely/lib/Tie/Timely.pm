package Tie::Timely;
use strict;

our $VERSION = '1.027';

sub TIESCALAR {
	my( $class, $value, $lifetime ) = @_;

	my $self = bless [ undef, $lifetime, time ], $class;

	$self->STORE( $value );

	return $self;
	}

sub FETCH { time - $_[0]->[2] > $_[0]->[1] ? () : $_[0]->[0] }

sub STORE { @{ $_[0] }[0,2] = ( $_[1], time ) }

1;

__END__

=encoding utf8

=head1 NAME

Tie::Timely - Time out scalar values

=head1 SYNOPSIS

	use Tie::Timely;

	my $interval = 5;
	tie my $scalar, 'Amelia', $interval;
	# now $scalar is 'Amelia'

	sleep 6;
	# now the interval has elapsed and the value is forgotten

	# set the value again and it starts a new interval
	$scalar = 'Llama';

=head1 DESCRIPTION

This module creates a tied scalar that forgets its value after the
interval that you specify. The next time you set the value it resets
the interval;

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/tie-timely/

=head1 AUTHOR

brian d foy, C<< <brian.d.foy@gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2005-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
