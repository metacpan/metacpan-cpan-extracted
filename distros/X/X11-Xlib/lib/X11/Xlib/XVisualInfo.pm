package X11::Xlib::XVisualInfo;
require X11::Xlib::Struct;
__END__

=head1 NAME

X11::Xlib::XVisualInfo - Struct to list details of a Visual*

=head1 SYNOPSIS

  my $conn= X11::Xlib->new();
  my @visuals= map { $_->unpack } $conn->XGetVisualInfo(0, my $foo);
  use DDP;
  p @visuals;

=head1 DESCRIPTION

The real "Visual" structure in Xlib is hidden from users, but various
functions give you XVisualInfo to be able to inspect a Visual without
making lots of method calls.

=head1 ATTRIBUTES

(copied from Xlib docs)

  typedef struct {
    Visual *visual;
    VisualID visualid;
    int screen;
    unsigned int depth;
    int class;
    unsigned long red_mask;
    unsigned long green_mask;
    unsigned long blue_mask;
    int colormap_size;
    int bits_per_rgb;
  } XVisualInfo;

=head1 METHODS

See parent class L<X11::Xlib::Struct>

=over 2

=item bits_per_rgb

=item blue_mask

=item class

=item colormap_size

=item depth

=item green_mask

=item red_mask

=item screen

=item visual

=item visualid

=back

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2023 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
