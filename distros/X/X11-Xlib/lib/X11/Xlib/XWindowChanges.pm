package X11::Xlib::XWindowChanges;
require X11::Xlib::Struct;
__END__

=head1 NAME

X11::Xlib::XWindowChanges - Struct defining window placement

=head1 DESCRIPTION

This struct contains various attributes of a window, to be applied
with L<XConfigureWindow|X11::Xlib/XConfigureWindow>.

=head1 ATTRIBUTES

Listed below is the C struct definition, and the constants that you pass to
XConfigureWindow to indicate whether the field is initialized.

  int x;                 /* CWX */
  int y;                 /* CWY */
  int width;             /* CWWidth */
  int height;            /* CWHeight */
  int border_width;      /* CWBorderWidth */
  Window sibling;        /* CWSibling */
  int stack_mode;        /* CWStackMode */

The constants can be exported with

  use X11::Xlib ':const_winattr';

=head1 METHODS

See parent class L<X11::Xlib::Struct>

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2021 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
