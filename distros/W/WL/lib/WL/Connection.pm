package WL::Connection;

=head1 NAME

WL::Connection - Estabilitsh connection for Wayland protocol

=head1 SYNOPSIS

  use WL::Connection;

  # Connect to Wayland server (compositor)
  my $conn = new WL::Connection;

  # Obtain the display object singleton
  my $display = $conn->get_display ();

  ...

  $conn->loop ();

=head1 DESCRIPTION

B<WL::Connection> takes care of estabilishing and tearing down a Wayland
protocol connection, marshalling and demarshalling the messages and event
processing. Moreover it bootstraps the B<WL::wl_display> singleton that is
essential for further communication via Wayland protocol.

Please consider this an alpha quality code, whose API can change at any time,
until we reach version 1.0.

=cut

use strict;
use warnings;

use IO::Socket::UNIX;
use Socket::MsgHdr;
use WL::Base;
use WL;

=head1 METHODS

=over 4

=item B<new>

Estabilish the connection. The display socket address is determined using
C<XDG_RUNTIME_DIR> and C<WAYLAND_DISPLAY> environment variables, falling back
to C<wayland-0> display.

=cut

sub new
{
	my $class = shift;
	my $self = {};

	my $xdg_home = $ENV{XDG_RUNTIME_DIR} || "/run/user/$<";
	my $wayland_display = $ENV{WAYLAND_DISPLAY} || 'wayland-0';
	my $addr = "$xdg_home/$wayland_display";
	$self->{conn} = new IO::Socket::UNIX ($addr) or die "$addr: $!";
	$self->{objs} = [undef];

	return bless $self, $class;
}

=item B<send> DATA [FILE]

Send a request. The data is aready marshalled message from a L<WL::Base>
subclass and the optional second argument is a file handle to be sent as
anciliary data alongside the message.

This should only be used by C<send_request> called from L<WL::Base> subclasses,
not directly.

=cut

sub send
{
	my $self = shift;
	my $data = shift;
	my $file = shift;

	my $shdr = new Socket::MsgHdr (buf => $data);
	$shdr->cmsghdr (SOL_SOCKET, SCM_RIGHTS, pack ('i', fileno $file))
		if $file;
	sendmsg ($self->{conn}, $shdr);
}

=item B<recv> LENGTH

Read an event, returning the data and optionally a file handle, if a file
descriptor is obtained from anciliary data.

This should only be used from C<process_event>, not directly.

=cut

sub recv
{
	my $self = shift;
	my $len = shift;
	my $file;

	return 0 unless $self->{conn};

	# 12 bytes the cmsg header, 4 bytes the 32-bit file descriptor payload
	my $chdr = new Socket::MsgHdr (buflen => $len, controllen => 12+4);

	recvmsg ($self->{conn}, $chdr) or return undef;
	my ($level, $type, $data) = $chdr->cmsghdr;

	# File descriptor received. Create a handle for it.
	if ($level and $type and $level == SOL_SOCKET and $type = SCM_RIGHTS) {
		open ($file, "+<&=", unpack ('i', $data)) or die $!;
	}

	return ($chdr->buf, $file || ());
}

=item B<send_request> ID OPCODE PAYLOAD [FILE]

Add message heading with id, opcode and length to already marshalled payload
and send it, optionally with an open file handle as anciliary data.

=cut

sub send_request
{
	my $self = shift;
	my $id = shift;
	my $opcode = shift;
	my $payload = shift;
	my $file = shift,

	my $length = 8 + length $payload;
	$self->send (pack ('L L a*', $id,
		(($length << 16) | $opcode), $payload), $file);
}

=item B<process_event>

Read a message, decode the header and call a C<callback> method (inherited from
L<WL::Base>) of its recipient with raw message body and optional file handle.

=cut

sub process_event
{
	my $self = shift;

	# First two words, identifying the recipient and length of the body
	my ($buf, $file) = $self->recv (8);
	die $! unless defined $buf;
	return 0 unless $buf;

	my ($id, $word2) = unpack 'LL', $buf;
	my $opcode = $word2 & 0x0000ffff;
	my $length = $word2 >> 16;

	# Read the body, we aready have first two words, the header
	($buf) = $self->recv ($length - 8) or die $!;
	$self->{objs}[$id]->callback ($opcode, $buf, $file);

	return 1;
}

=item B<get_display>

Create and return a L<WL::wl_display> singleton object.

=cut

sub get_display
{
	my $self = shift;
	return new WL::wl_display ($self);
}

=item B<round_trip> DISPLAY

Issue a C<sync> call for the display object and wait for C<done> event receipt.

As Wayland ensures the calls are processed in order, this creates a barrier in
message stream.

=cut

sub round_trip
{
	my $self = shift;
	my $display = shift;

	my $finished = 0;
	my $done = $display->sync ();
	$done->{'WL::wl_callback::done'} = sub {
		$finished = 1;
	};

	while (not $finished) {
		last unless $self->process_event ();
	}
}

=item B<loop>

Process the events until the connection tears down.

=cut

sub loop
{
	my $self = shift;
	while ($self->process_event ()) {};
}

=item B<disconnect>

Tear down the connection.

=cut

sub disconnect
{
	my $self = shift;
	close delete $self->{conn};
}

=back

=head1 SEE ALSO

=over

=item *

L<http://wayland.freedesktop.org/> -- Wayland project web site

=item *

L<WL::Base> -- Base class for Wayland objects

=back

=head1 COPYRIGHT

Copyright 2013 Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Lubomir Rintel C<lkundrak@v3.sk>

=cut

1;
