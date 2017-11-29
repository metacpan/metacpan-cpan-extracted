package ZMQ::Raw::Loop::Handle;
$ZMQ::Raw::Loop::Handle::VERSION = '0.19';
use strict;
use warnings;
use Carp;

sub CLONE_SKIP { 1 }

my @attributes;

BEGIN
{
	@attributes = qw/
		handle
		timer
		loop
		timeout
		on_readable
		on_writable
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

ZMQ::Raw::Loop::Handle - Handle class

=head1 VERSION

version 0.19

=head1 DESCRIPTION

A L<ZMQ::Raw::Loop::Handle> represents a handle.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 SYNOPSIS

	use ZMQ::Raw;

	my $handle = ZMQ::Raw::Loop::Handle->new
	(
		handle => $handle,
		timeout => 30,

		on_readable => sub
		{
		},
		on_writable => sub
		{
		},
		on_timeout => sub
		{
		},
	);

	my $loop = ZMQ::Raw::Loop->new;
	$loop->add ($handle);
	$loop->run;

=head1 METHODS

=head2 new( %args )

Create a new handle.

=cut

sub new
{
	my ($this, %args) = @_;

	if (!$args{handle})
	{
		croak "handle not provided";
	}

	if (!$args{on_readable} && !$args{on_writable})
	{
		croak "on_readable or on_writable needed";
	}

	if ($args{on_readable} && ref ($args{on_readable}) ne 'CODE')
	{
		croak "on_readable not a code ref";
	}

	if ($args{on_writable} && ref ($args{on_writable}) ne 'CODE')
	{
		croak "on_writable not a code ref";
	}

	if ($args{on_timeout} && ref ($args{on_timeout}) ne 'CODE')
	{
		croak "on_timeout not a code ref";
	}

	if ($args{on_timeout} && !exists ($args{timeout}))
	{
		croak "on_timeout provided but timeout not set";
	}

	my $class = ref ($this) || $this;
	my $self =
	{
		handle => $args{handle},
		timeout => $args{timeout},
		on_readable => $args{on_readable},
		on_writable => $args{on_writable},
		on_timeout => $args{on_timeout},
	};

	return bless $self, $class;
}

=for Pod::Coverage handle timer loop timeout on_readable on_writable on_timeout

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Loop::Handle
