package ZMQ::Raw::Loop::Timer;
$ZMQ::Raw::Loop::Timer::VERSION = '0.34';
use strict;
use warnings;
use Scalar::Util qw/weaken/;
use Carp;

sub CLONE_SKIP { 1 }

my @attributes;

BEGIN
{
	@attributes = qw/
		timer
		on_cancel
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

ZMQ::Raw::Loop::Timer - Timer class

=head1 VERSION

version 0.34

=head1 DESCRIPTION

A L<ZMQ::Raw::Loop::Timer> represents a timer, usable in a
L<ZMQ::Raw::Loop>.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 SYNOPSIS

	use ZMQ::Raw;

	my $context = ZMQ::Raw::Context->new;
	my $loop = ZMQ::Raw::Loop->new ($context);

	my $timer = ZMQ::Raw::Loop::Timer->new
	(
		timer => ZMQ::Raw::Timer->new ($context, after => 100),
		on_timeout => sub
		{
			print "Timed out!\n";
			$loop->terminate();
		},
		on_cancel => sub
		{
			print "Cancelled!\n";
		},
	);

	$loop->add ($timer);
	$loop->run;

=head1 METHODS

=head2 new( )

Create a new loop timer.

=head2 cancel( )

Cancel the underlying timer.

=head2 reset( )

Reset the underlying timer.

=head2 expire( )

Expire the underlying timer.

=head2 running( )

Check if the timer is running.

=cut

sub new
{
	my ($this, %args) = @_;

	if (!$args{timer} || ref ($args{timer}) ne 'ZMQ::Raw::Timer')
	{
		croak "timer not provided or not a 'ZMQ::Raw::Timer'";
	}

	if (!$args{on_timeout} || ref ($args{on_timeout}) ne 'CODE')
	{
		croak "on_timeout not a code ref";
	}

	if ($args{on_cancel} && ref ($args{on_cancel}) ne 'CODE')
	{
		croak "on_cancel not a code ref";
	}

	my $class = ref ($this) || $this;
	my $self =
	{
		timer => $args{timer},
		on_timeout => $args{on_timeout},
		on_cancel => $args{on_cancel},
	};

	return bless $self, $class;
}



sub loop
{
	my ($this, $loop) = @_;

	if (scalar (@_) > 1)
	{
		$this->{loop} = $loop;
		weaken ($this->{loop});
	}

	return $this->{loop};
}



sub cancel
{
	my ($this) = @_;

	$this->timer->cancel;

	if ($this->loop)
	{
		$this->loop->remove ($this);

		if ($this->on_cancel)
		{
			&{$this->on_cancel}();
		}
	}
}



sub reset
{
	my ($this) = @_;

	$this->timer->reset;

	if ($this->loop)
	{
		$this->loop->remove ($this);
		$this->loop->add ($this);
	}
}



sub expire
{
	my ($this) = @_;

	$this->timer->expire;
}



sub running
{
	my ($this) = @_;

	return $this->timer->running;
}

=for Pod::Coverage timer loop on_cancel on_timeout

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Loop::Timer
