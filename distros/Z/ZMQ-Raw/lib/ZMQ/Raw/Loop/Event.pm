package ZMQ::Raw::Loop::Event;
$ZMQ::Raw::Loop::Event::VERSION = '0.25';
use strict;
use warnings;
use Carp;

sub CLONE_SKIP { 1 }

my @attributes;

BEGIN
{
	@attributes = qw/
		read_handle
		write_handle
		loop
		timeout
		timer
		on_set
		on_timeout
	/;

	no strict 'refs';
	foreach my $accessor (@attributes)
	{
		*{$accessor} = sub
		{
			@_ > 1 ? $_[0]->{$accessor} = $_[1] : $_[0]->{$accessor}
		};
	}
}

use ZMQ::Raw;

=head1 NAME

ZMQ::Raw::Loop::Event - Event class

=head1 VERSION

version 0.25

=head1 DESCRIPTION

A L<ZMQ::Raw::Loop::Event> represents an event, usable in a
L<ZMQ::Raw::Loop>.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 SYNOPSIS

	use ZMQ::Raw;

	my $event = ZMQ::Raw::Loop::Event->new
	(
		$ctx,
		on_set => sub
		{
			print "Event set!\n";
		},
		timeout => 10000,
		on_timeout =>
		{
			print "Event timed out\n";
		}
	);

	my $timer = ZMQ::Raw::Loop::Timer->new
	(
		timer => ZMQ::Raw::Timer->new ($ctx, after => 100),
		on_timeout => sub
		{
			$event->set;
		},
	);

	my $loop = ZMQ::Raw::Loop->new;
	$loop->add ($event);
	$loop->run;

=head1 METHODS

=head2 new( $context, %args )

Create a new loop event

=head2 set( )

Set the event

=head2 reset( )

Reset the event

=cut

our $id = 0;

sub new
{
	my ($this, $context, %args) = @_;

	if (!defined ($context) || ref ($context) ne 'ZMQ::Raw::Context')
	{
		croak "context not set or not a 'ZMQ::Raw::Context'";
	}

	if (!$args{on_set} || ref ($args{on_set}) ne 'CODE')
	{
		croak "on_set not set or not a code ref";
	}

	if ($args{on_timeout} && ref ($args{on_timeout}) ne 'CODE')
	{
		croak "on_timeout not a code ref";
	}

	if ($args{on_timeout} && !exists ($args{timeout}))
	{
		croak "on_timeout provided but timeout not set";
	}

	my $endpoint = "inproc://_loop_event-".(++$id);
	my $read = ZMQ::Raw::Socket->new ($context, ZMQ::Raw->ZMQ_PAIR);
	$read->bind ($endpoint);

	my $write = ZMQ::Raw::Socket->new ($context, ZMQ::Raw->ZMQ_PAIR);
	$write->connect ($endpoint);

	my $class = ref ($this) || $this;
	my $self =
	{
		read_handle => $read,
		write_handle => $write,
		timeout => $args{timeout},
		on_set => $args{on_set},
		on_timeout => $args{on_timeout},
	};

	return bless $self, $class;
}



sub set
{
	my ($this) = @_;

	$this->write_handle->send ('', ZMQ::Raw->ZMQ_DONTWAIT);
}



sub reset
{
	my ($this) = @_;

AGAIN:
	goto AGAIN if (defined ($this->read_handle->recv (ZMQ::Raw->ZMQ_DONTWAIT)));
}

=for Pod::Coverage read_handle write_handle loop timeout timer on_set on_timeout

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Loop::Event
