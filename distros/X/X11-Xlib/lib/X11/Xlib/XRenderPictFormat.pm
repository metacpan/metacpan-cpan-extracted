package X11::Xlib::XRenderPictFormat;
require X11::Xlib::Struct;
__END__

=head1 NAME

X11::Xlib::XRenderPictFormat - Struct defining color format for XRender

=head1 ATTRIBUTES

The fields of the struct are a merger of two C structs, with all the "direct."
members inlined with an underscore.

  PictFormat id             /* XID */
  int type                  
  int depth
  short direct_red
  short direct_redMask
  short direct_green
  short direct_greenMask
  short direct_blue
  short direct_blueMask
  short direct_alpha
  short direct_alphaMask
  Colormap colormap         /* XID */

=head1 METHODS

See parent class L<X11::Xlib::Struct>

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
