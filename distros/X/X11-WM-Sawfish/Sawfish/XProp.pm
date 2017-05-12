package X11::WM::Sawfish::XProp;

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
our $VERSION = '0.01';

use X11::Protocol;

use constant XA_CARDINAL =>  6;
use constant XA_STRING   => 31;

use constant PROTOCOL_X11_VERSION => 1;

sub new {
  my ($package, $display) = @_;
  $package = ref($package) || $package;
  my ($self) = {};
  bless($self, $package);
  $self->{Display} = X11::WM::Sawfish::canonical_display_name($display);
  $self->get_server_version();
  if (!defined($self->{Display})) {
    $!=111; # Connection refused
    return(undef);
  }
  return($self);
}

sub open_xserver {
  my ($self) = @_;
  if (!defined($self->{X11})) {
    my ($x) = $self->{X11} = new X11::Protocol($self->{Display});
    if (defined($x)) {
      my ($value, $type, $format, $bytes_after) =
          $x->GetProperty($x->root, $x->atom("_SAWFISH_REQUEST_WIN"),
                          XA_CARDINAL, 0, 1, 0);
      if (($type == XA_CARDINAL) && ($format == 32)) {
        $self->{ServerRequestWindow} = unpack("I", $value);
        $x->{event_handler} = "queue";
        my $event_mask = $x->pack_event_mask("PropertyChange");
        my $crwin = $x->new_rsrc();
        $x->CreateWindow($crwin, $x->root, 0, 0, 0, -100, -100, 10, 10, 0,
                         "event_mask" => $event_mask);
        $self->{ClientRequestWindow} = $crwin;
        $self->{RequestProperty}     = $x->atom("_SAWFISH_REQUEST");
      } else { $self->{X11} = undef; }
    }
  }
  return($self->{X11});
}

sub close_xserver {
  my ($self) = @_;
  my $x = $self->{X11};
  $x->DestroyWindow($x->{ClientRequestWindow});
  undef($self->{X11});
}

sub eval_form {
  my ($self, $form) = @_;
  my ($resp, $state);
  my $x = $self->open_xserver();
  $resp = undef;
  if (defined($x)) {
    $x->ChangeProperty($self->{ClientRequestWindow},
                       $self->{RequestProperty},
                       XA_STRING, 8, 'Replace', $form);

    # Gobble up the PropertyChangeEvent that we will get
    $x->next_event();

    my $event = $x->pack_event('name'   => 'ClientMessage',
                               'window' => $x->root,
                               'type'   => $self->{RequestProperty},
                               'format' => 32,
                               'data'   => pack("LLLLL",
                                                  PROTOCOL_X11_VERSION,
                                                  $self->{ClientRequestWindow},
                                                  $self->{RequestProperty},
                                                  1, 0));
    $x->SendEvent($self->{ServerRequestWindow}, 0, 0, $event);

    # Wait for Sawfish to update our request property with the results
    $x->next_event();

    my ($value, $type, $format, $bytes_after);
    my $len = 1024;
    do {
      ($value, $type, $format, $bytes_after) =
        $x->GetProperty($self->{ClientRequestWindow},
                        $self->{RequestProperty},
                        XA_STRING, 0, $bytes_after, 0);
      $len += $bytes_after;
    } while ($bytes_after > 0);
    ($state, $resp) = unpack("Ca*", $value);
    if ($state != 1) { $resp = undef; }
  }
  return($resp);
}

1;
__END__

=head1 NAME

X11::WM::Sawfish::XProp - Perl extension for sending LISP forms to the sawfish window manager using X server window properties.

=head1 SYNOPSIS

  use X11::WM::Sawfish::XProp;

  my $x = new X11::WM::Sawfish::XProp();

  $x->eval_form('(display-message "Foo")');

=head1 ABSTRACT

X11::WM::Sawfish::XProp implements the communication protocol used to connect to
a running instance of the Sawfish window manager with UNIX domain sockets.

=head1 DESCRIPTION

The Sawfish window manager supports two schemes for submitting LISP forms
for evaluation.  This module implements the X server windows properties scheme.

To use X11::WM::Sawfish::XProp, simply create an instance the same way as with
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
