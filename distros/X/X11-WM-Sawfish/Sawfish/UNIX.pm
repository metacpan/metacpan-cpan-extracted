package X11::WM::Sawfish::UNIX;

# Copyright (C) 2003 Craig B. Agricola.  All rights reserved.  This library is
# free software; you can redistribute it and/or modify it under the same terms
# as Perl itself. 

use 5.005;
use strict;
use warnings;

require Exporter;

use X11::WM::Sawfish;
our @ISA = qw(X11::WM::Sawfish);
our @EXPORT_OK = qw();
our @EXPORT = qw();
our $VERSION = '0.02';

use IO qw(Socket);

use constant req_eval           =>   0;
use constant req_eval_async     =>   1;
use constant req_end_of_session => 255;

sub new {
  my ($package, $display) = @_;
  $package = ref($package) || $package;
  my ($self) = {};
  bless($self, $package);
  $self->{SocketPath} = X11::WM::Sawfish::sawfish_socket_name($display);
  $self->get_server_version();
  if (!defined($self->{Socket})) {
    $!=111; # Connection refused
    return(undef);
  }
  $self->close_socket();
  return($self);
}

sub open_socket {
  my ($self) = @_;
  if (!defined($self->{Socket})) {
    $self->{Socket} = new IO::Socket::UNIX(Peer => $self->{SocketPath});
  }
  return($self->{Socket});
}

sub close_socket {
  my ($self) = @_;
  syswrite($self->{Socket}, pack("C", req_end_of_session));
  close($self->{Socket});
  undef($self->{Socket});
}

sub eval_form {
  my ($self, $form) = @_;
  my ($resp_len, $resp, $state);
  my $s = $self->open_socket();
  $resp = undef;
  if (defined($s)) {
    my $data = pack("CIa*", req_eval, length($form), $form);
    syswrite($s, $data);
    sysread($s, $data, 4);
    $resp_len = unpack("I", $data);
    sysread($s, $resp, $resp_len);
    ($state, $resp) = unpack("Ca*", $resp);
    if ($state != 1) { $resp = undef; }
  }
  return($resp);
}

1;
__END__

=head1 NAME

X11::WM::Sawfish::UNIX - Perl extension for sending LISP forms to the sawfish window manager over UNIX domain sockets.

=head1 SYNOPSIS

  use X11::WM::Sawfish::UNIX;

  my $x = new X11::WM::Sawfish::UNIX($display);

  $x->eval_form('(display-message "Foo")');

=head1 ABSTRACT

X11::WM::Sawfish::UNIX implements the communication protocol used to connect to
a running instance of the Sawfish window manager with UNIX domain sockets.

=head1 DESCRIPTION

The Sawfish window manager supports two schemes for submitting LISP forms
for evaluation.  This module implements the UNIX domain sockets scheme.

To use X11::WM::Sawfish::UNIX, simply create an instance the same way as with
L<X11::WM::Sawfish>, and use it the same way.  The methods available are the
same as well.

=head1 SEE ALSO

sawfish(1), sawfish-client(1), L<X11::WM::Sawfish>

=head1 AUTHOR

Craig B. Agricola, E<lt>craig@theagricolas.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Craig B. Agricola

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
