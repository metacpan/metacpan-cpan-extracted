package X11::Xlib::XSetWindowAttributes;
require X11::Xlib::Struct;
__END__

=head1 NAME

X11::Xlib::XSetWindowAttributes - Struct defining window attributes

=head1 DESCRIPTION

This struct contains various attributes of a window, to be applied
with calls like L<XCreateWindow|X11::Xlib/XCreateWindow>
or L<XChangeWindowAttributes|X11::Xlib/XChangeWindowAttributes>.

=head1 ATTRIBUTES

(copied from X11 docs)

  Pixmap background_pixmap;       /* background, None, or ParentRelative */
  unsigned long background_pixel; /* background pixel */
  Pixmap border_pixmap;           /* border of the window or CopyFromParent */
  unsigned long border_pixel;     /* border pixel value */
  int bit_gravity;                /* one of bit gravity values */
  int win_gravity;                /* one of the window gravity values */
  int backing_store;              /* NotUseful, WhenMapped, Always */
  unsigned long backing_planes;   /* planes to be preserved if possible */
  unsigned long backing_pixel;    /* value to use in restoring planes */
  Bool save_under;                /* should bits under be saved? (popups) */
  long event_mask;                /* set of events that should be saved */
  long do_not_propagate_mask;     /* set of events that should not propagate */
  Bool override_redirect;         /* boolean value for override_redirect */
  Colormap colormap;              /* color map to be associated with window */
  Cursor cursor;                  /* cursor to be displayed (or None) */

Several Xlib functions allow you to specify which fields are defined rather
than forcing you to apply all attributes at once.  The constants to indicate
which fields are use can be exported with

  use X11::Xlib ':const_winattr';
  
  # CWBackPixel CWBackPixmap CWBackingPixel CWBackingPlanes CWBackingStore
  # CWBitGravity CWBorderPixel CWBorderPixmap CWColormap CWCursor
  # CWDontPropagate CWEventMask CWOverrideRedirect CWSaveUnder CWWinGravity

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
