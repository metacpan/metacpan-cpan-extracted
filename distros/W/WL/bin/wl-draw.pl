#!/usr/bin/perl

=head1 NAME

wl-draw.pl - Perl Wayland demo

=head1 SYNOPSIS

B<wl-draw.pl>

=head1 DESCRIPTION

This is an example application written using Perl bindings for Wayland protocol
demonstrating the use and capabilities of the package. It creates a surface and
continually updates its contents with random ARGB color noise.

=cut

use WL::Connection;
use File::Temp qw/tempfile/;

use strict;
use warnings;

my $width = 100;
my $height = 100;
my $depth = 4;

# Connect to the server, compositor
my $conn = new WL::Connection;

# Obtain the instance of WL::wl_display singleton
my $display = $conn->get_display ();

# Respond to the events
$display->{'WL::wl_display::delete_id'} = sub {
};
$display->{'WL::wl_display::error'} = sub {
	my $self = shift;
	my $object = shift;
	my $code = shift;
	my $message = shift;

	warn $message;
};

# We'll need these objects for drawing and displaying, we'll remember them
# as soon as they're announced via a global event
my ($shm, $shell, $compositor);

# We'll also need to remember which pixel formats are supported.
my %formats;

# Obtain the global object registry
my $registry = $display->get_registry ();
$registry->{'WL::wl_registry::global'} = sub {
	my $self = shift;
	my $id = shift;
	my $class = shift;
	my $version = shift;

	if ($class eq 'wl_shm') {
		$shm = $registry->bind ($id, $class, $version);
		$shm->{'WL::wl_shm::format'} = sub {
			my $self = shift;
			my $format = shift;

			$formats{$format} = 1;
		};
		$conn->round_trip ($display);
	}
	elsif ($class eq 'wl_shell') {
		$shell = $registry->bind ($id, $class, $version);
		$conn->round_trip ($display);
	}
	elsif ($class eq 'wl_compositor') {
		$compositor = $registry->bind ($id, $class, $version);
		$conn->round_trip ($display);
	}
};
# Ensure everything up to here was processed and therefore we have all the
# required objects and information we bound and requested above
$conn->round_trip ($display);

# A sanity check
die 'ARGB8888 not supported' unless $formats{WL::wl_shm::FORMAT_ARGB8888};

# Nothing new specific to Perl bindings here...
my $surface = $compositor->create_surface ();
my $shell_surface = $shell->get_shell_surface ($surface);
$shell_surface->{'WL::wl_shell_surface::ping'} = sub {
	my $self = shift;
	my $serial = shift;
	$self->pong ($serial);
};
$shell_surface->set_title ("Hello from Perl!");
$shell_surface->set_toplevel ();

# Obtain a file handle for contents that we'll render into that we'd send to
# the server and allocate the desired space
my $file = tempfile ();
unlink $file;
truncate $file, ($width * $height * $depth);

# Now share our buffer with the server
my $pool = $shm->create_pool ($file, $width * $height * $depth);
my $buffer = $pool->create_buffer (0, $width, $height, $width * $depth,
	WL::wl_shm::FORMAT_ARGB8888);
$buffer->{'WL::wl_buffer::release'} = sub {
};

do {
	# Render the noise
	seek $file, 0, 0;
	print $file $_ foreach (map {chr(rand(0x100))}
		0..($width * $height * $depth));
	flush $file;

	# And let the compositor know
	$surface->attach ($buffer, 0, 0);
	$surface->damage (0, 0, $width, $height);
	$surface->commit ();

	# This is here so that we don't render more quickly that the server
	# is able to consume
	$conn->round_trip ($display);
} while (1);

=head1 SEE ALSO

=over

=item *

L<http://wayland.freedesktop.org/> -- Wayland project web site

=item *

L<WL::Connection> -- Estabilish a Wayland connection

=back

=head1 COPYRIGHT

Copyright 2013 Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Lubomir Rintel C<lkundrak@v3.sk>

=cut
