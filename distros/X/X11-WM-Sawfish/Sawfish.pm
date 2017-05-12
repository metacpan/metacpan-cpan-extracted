package X11::WM::Sawfish;

# Copyright (C) 2003 Craig B. Agricola.  All rights reserved.  This library is
# free software; you can redistribute it and/or modify it under the same terms
# as Perl itself. 

use 5.005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw();
our @EXPORT = qw();
our $VERSION = '0.03';

use Sys::Hostname;

use X11::WM::Sawfish::UNIX;
use X11::WM::Sawfish::XProp;

sub new {
  my $package = shift(@_);
  $package = ref($package) || $package;
  my ($self) = new X11::WM::Sawfish::UNIX(@_);
  if (!defined($self)) {
    $self = new X11::WM::Sawfish::XProp(@_);
  }
  return($self);
}

sub canonical_display_name {
  my ($display) = @_;
  if (!defined($display)) { $display = $ENV{"DISPLAY"}; }
  $display =~ s/^unix:/:/;
  if (substr($display, 0, 1) eq ":") {
    $display = hostname() . $display;
  }
  my $i = index($display, ":");
  if (($i > -1) && (index($display, ".", $i) == -1))
  {
    $display .= ".0";
  }
  return($display);
}

sub sawfish_socket_name {
  my ($display) = @_;
  my $socket = sprintf("/tmp/.sawfish-%s/%s",
                       (getpwuid($<))[0], canonical_display_name($display));
  return($socket);
}

sub get_server_version {
  my ($self) = @_;
  my ($response) = $self->eval_form("sawfish-version");
  if (defined($response)) {
    $response =~ s#^"##;
    $response =~ s#"$##;
    $self->{ServerVersion} = $response;
  }
  return($response);
}

sub ServerVersion {
  return($_[0]->{ServerVersion});
}

1;
__END__

=head1 NAME

X11::WM::Sawfish - Perl extension for sending LISP forms to the sawfish window manager for processing.

=head1 SYNOPSIS

  use X11::WM::Sawfish;

  my $x = new X11::WM::Sawfish($display);

  $x->eval_form('(display-message "Foo")');

=head1 ABSTRACT

X11::WM::Sawfish implements the communication protocols used to connect to a
running instance of the Sawfish window manager and send LISP forms for
evaluation.

=head1 DESCRIPTION

The Sawfish window manager is designed around a LISP dialect implemented by
librep.  As such, configuration can be done with arbitrary LISP forms.  This
can be in the configuration files, or it can be submitted by external
processes with two different communications schemes.  The first is with
simple UNIX domain sockets.
The second scheme is to use the standard X11 properties mechanism to submit
LISP forms for evaluation.

To use X11::WM::Sawfish, simply create an instance, which will connect to the
Sawfish window manager running on the X server pointed to by the argument.  If
no argument is given, the C<$DISPLAY> environment variable will be used.  Then
use the C<eval_form()> method to submit LISP forms for evaluation.  The scheme
used for connection will by default be the UNIX domain socket scheme, unless
that method fails (which will only happen if the X server is running on a
remote machine) in which case it will fall back to the X properties scheme.

Keep in mind that by default, the X properties scheme is disabled by Sawfish
for security reasons.  To enable it, the LISP form C<(server-net-init)> must be
evalutated.  Make sure that you have secured your X server before you do this,
because if you don't, anyone can connect to your Sawfish process and execute
arbitrary LISP forms, which would include the ability to execute arbitrary
system commands.

=head2 Methods

=head3 new($display)

Creates a new X11::WM::Sawfish object which will connect to the Sawfish window
manager that is running on the X server pointed to by the argument.  If the
argument is not given, the C<$DISPLAY> environment variable will be used.  If
the connection is not able to be created, new will return C<undef> and set
C<$!>.

=head3 eval_form($string)

Takes the LISP form represented by string and submits it to the librep
running in the Sawfish process.  The results are returned (as a string).  If
the connection has been closed, it will automatically be reopened.

=head3 open_socket()

Attempts to open a connection to the Sawfish process.

=head3 close_socket()

Attempts to close the connection to the Sawfish process.

=head3 ServerVersion()

Returns the version number returned by the server when the initial connection
was made (during object construction).

=head1 SEE ALSO

sawfish(1), sawfish-client(1), L<X11::WM::Sawfish::UNIX>,
L<X11::WM::Sawfish::XProp>

=head1 AUTHOR

Craig B. Agricola, E<lt>craig@theagricolas.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Craig B. Agricola

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
