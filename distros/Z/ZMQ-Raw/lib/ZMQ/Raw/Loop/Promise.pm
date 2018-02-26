package ZMQ::Raw::Loop::Promise;
$ZMQ::Raw::Loop::Promise::VERSION = '0.24';
use strict;
use warnings;
use Carp;

sub CLONE_SKIP { 1 }

my @attributes;

BEGIN
{
	@attributes = qw/
		loop
		status
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

use constant PLANNED => 0;
use constant KEPT    => 1;
use constant BROKEN  => 2;

=head1 NAME

ZMQ::Raw::Loop::Promise - Promise class

=head1 VERSION

version 0.24

=head1 DESCRIPTION

A L<ZMQ::Raw::Loop::Promise> represents a promise

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 SYNOPSIS

	use ZMQ::Raw;

	my $context = ZMQ::Raw::Context->new;
	my $loop = ZMQ::Raw::Loop->new ($context);

	my $promise = ZMQ::Raw::Loop::Promise->new ($loop);
	$promise->then (sub
		{
			my $promise = shift;
			print "Promise kept/broken: ", $promise->result, "\n";
		}
	);

	my $timer = ZMQ::Raw::Loop::Timer->new (
		timer => ZMQ::Raw::Timer->new ($context, after => 100),
		on_timeout => sub
		{
			$promise->keep ('done');
		}
	);

	$loop->add ($timer);
	$loop->run();

=head1 METHODS

=head2 new( $loop )

Create a new promise.

=head2 status( )

Get the status of the promise. One of C<PLANNED>, C<KEPT> or C<BROKEN>.

=head2 await( )

Wait for the promise to be kept or broken.

=head2 result( )

Wait for the promise to be kept or broken, if its kept the result will be
returned, otherwise throws the cause.

=head2 cause( )

Get the reason why the promise was broken. This method will croak if the promise
is still planned or has been kept.

=head2 break( $result )

Break the promise, setting the cause to C<$result>.

=head2 keep( $result )

Keep the promise, setting its result to C<$result>.

=head2 then( \&callback )

Schedule C<\&callback> to be fired when the promise is either kept or broken. Returns
a new C<ZMQ::Raw::Loop::Promise>.

=cut

sub new
{
	my ($this, $loop) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		loop => $loop,
		status => &PLANNED,
	};

	return bless $self, $class;
}

sub await
{
	my ($this) = @_;

	while ($this->status == &PLANNED)
	{
		if ($this->loop->terminated)
		{
			$this->break();
			return;
		}

		$this->loop->run_one;
	}
}

sub keep
{
	my ($this, $result) = @_;

	$this->{result} = $result;
	$this->status (&KEPT);

	if ($this->{then})
	{
		&{$this->{then}}();
		$this->{then} = undef;
	}
}

sub break
{
	my ($this, $cause) = @_;

	$this->{cause} = $cause;
	$this->status (&BROKEN);

	if ($this->{then})
	{
		&{$this->{then}}();
		$this->{then} = undef;
	}
}

sub then
{
	my ($this, $then) = @_;

	if ($this->status != &PLANNED)
	{
		croak "promise not planned";
	}

	my $promise = ZMQ::Raw::Loop::Promise->new ($this->loop);

	$this->{then} = sub
	{
		my $result = eval { &{$then} ($this) };
		if ($@)
		{
			$promise->break ($@);
			return;
		}

		$promise->keep ($result);
	};

	return $promise;
}

sub result
{
	my ($this) = @_;

	$this->await();
	if ($this->status == &KEPT)
	{
		return $this->{result};
	}

	die $this->{cause};
}

sub cause
{
	my ($this) = @_;

	if ($this->status != &BROKEN)
	{
		croak "promise not broken";
	}

	return $this->{cause};
}

=head1 CONSTANTS

=head2 PLANNED

The promise is still planned.

=head2 KEPT

The promise has been kept.

=head2 BROKEN

The promise was broken.

=for Pod::Coverage loop

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Loop::Promise
