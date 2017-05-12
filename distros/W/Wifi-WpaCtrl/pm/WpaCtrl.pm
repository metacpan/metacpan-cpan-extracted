package Wifi::WpaCtrl;

use strict;
use warnings;
use DynaLoader;

our @ISA = qw( DynaLoader );
our $VERSION = 0.02;

sub dl_load_flags { 0x01 }

bootstrap Wifi::WpaCtrl $VERSION;

sub DESTROY {
	my $self = shift;
	$self->close();
}

1;

=pod

=head1 NAME

Wifi::WpaCtrl - wpa_supplicant/hostapd control interface library

=head1 SYNOPSIS

  use Wifi::WpaCtrl;

  $wpa = Wifi::WpaCtrl->new('/path/to/socket') or die;
  $reply = $wpa->request('PING');

=head1 DESCRIPTION

This module is a wrapper around wpa_ctrl.[ch] supplied by
wpa_supplicant. It may be used to communicate with
wpa_supplicant/hostapd in various ways.

=head1 METHODS

=head2 new

  $wpa = Wifi::WpaCtrl->new('/path/to/socket');

This class method tries to open a control interface connection to
wpa_supplicant/hostap. The first argument is the path to the socket to
connect to (usually /var/run/wpa_supplicant or /var/run/hostap). This
argument may be omited if UDP sockets are used (Win32). It returns a
new Wifi::WpaCtrl instance on success or undef on failure.

=head2 close

  $wpa->close();

Closes the control interface. Returns nothing useful. You don't need
to call this method yourself usually. It'll get executed automatically
when Perl tries to free the Wifi::WpaCtrl instance when it leaves its
scope.

=head2 request

  my $reply = $wpa->request('PING');

This method send a command which is given as the first argument to
wpa_supplicant/hostapd. On success it returns the recieved reply. It
may also return undef on error (send or recieve failed). On timeout (2
		seconds) it croaks. This should never happen, though, as the
only reason for that may be wpa_supplicant/hostapd sending a message
at the same time the B<request> method is called. This could happen if
you have used B<attach> on the same Wifi::WpaCtrl instance to register
it as a monitor for event messages. You should never do that. Instead
you can create two Wifi::WpaCtrl instances. One for sending requests
and one for recieving events.

=head2 attach

  $wpa->attach();

Register as an event monitor for the control interface. Returns 1 on
success, 0 on failure or undef on timeout.

=head2 detach

  $wpa->detach();

Unregister event monitor from the control interface. Returns 1 on success, 0 on failure or undef on timeout.

=head2 recv

  my $reply = $wpa->recv();

Receive a pending control interface message. Returns the recieved message on success or undef on failure.

=head2 pending

  $is_pending = $wpa->pending();

Check whether there are pending event messages. Returns non-zero if there are pending messages.

=head2 get_fd

  my $fd = $wpa->get_fd();

Get file descriptor used by the control interface.

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Florian Ragwitz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
