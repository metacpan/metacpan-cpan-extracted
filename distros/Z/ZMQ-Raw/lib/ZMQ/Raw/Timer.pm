package ZMQ::Raw::Timer;
$ZMQ::Raw::Timer::VERSION = '0.31';
use strict;
use warnings;
use Carp;
use ZMQ::Raw;

sub CLONE_SKIP { 1 }

=head1 NAME

ZMQ::Raw::Timer - ZeroMQ Timer class

=head1 VERSION

version 0.31

=head1 DESCRIPTION

A L<ZMQ::Raw::Timer> represents a timer.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 SYNOPSIS

	use ZMQ::Raw;

	# Create a 200ms timer
	my $timer = ZMQ::Raw::Timer->new ($ctx,
		after => 200
	);

=head1 METHODS

=head2 new( $context, %args )

Create a new timer class. C<%args> may have 2 optional members,
C<after> to specify the number of milliseconds before the timer
will initially fire, and/or C<interval> if the timer has to fire
repeatedly.

=cut

sub new
{
	my ($class, $ctx, %args) = @_;
	return $class->_new ($ctx, $args{after} || 0, $args{interval});
}



sub cancel
{
	my ($this) = @_;
	$this->_cancel();

AGAIN:
	goto AGAIN if (defined ($this->socket->recv (ZMQ::Raw->ZMQ_DONTWAIT)));
}



sub reset
{
	my ($this) = @_;
	$this->_reset();

AGAIN:
	goto AGAIN if (defined ($this->socket->recv (ZMQ::Raw->ZMQ_DONTWAIT)));
}

=head2 id ()

Get the timer's id

=head2 reset( )

Reset the timer

=head2 cancel( )

Cancel the timer

=head2 expire( )

Expire the timer

=head2 socket( )

Get the underlying L<C<ZMQ::Raw::Socket>> that will be readable
when the timer has elapsed.

=head2 running( )

Check if the timer is running.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Socket
