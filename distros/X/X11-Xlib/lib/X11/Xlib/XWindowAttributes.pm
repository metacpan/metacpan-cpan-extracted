package X11::Xlib::XWindowAttributes;
require X11::Xlib::Struct;
__END__

=head1 NAME

X11::Xlib::XWindowAttributes - Struct defining window attributes

=head1 DESCRIPTION

This struct contains various attributes of a window, which can be retrieved
with L<XGetWindowAttributes|X11::Xlib/XGetWindowAttributes>.

=head1 ATTRIBUTES

(copied from X11 docs)

    int x, y;                     /* location of window */
    int width, height;            /* width and height of window */
    int border_width;             /* border width of window */
    int depth;                    /* depth of window */
    Visual *visual;               /* the associated visual structure */
    Window root;                  /* root of screen containing window */
    int class;                    /* InputOutput, InputOnly*/
    int bit_gravity;              /* one of the bit gravity values */
    int win_gravity;              /* one of the window gravity values */
    int backing_store;            /* NotUseful, WhenMapped, Always */
    unsigned long backing_planes; /* planes to be preserved if possible */
    unsigned long backing_pixel;  /* value to be used when restoring planes */
    Bool save_under;              /* boolean, should bits under be saved? */
    Colormap colormap;            /* color map to be associated with window */
    Bool map_installed;           /* boolean, is color map currently installed*/
    int map_state;                /* IsUnmapped, IsUnviewable, IsViewable */
    long all_event_masks;         /* set of events all people have interest in*/
    long your_event_mask;         /* my event mask */
    long do_not_propagate_mask;   /* set of events that should not propagate */
    Bool override_redirect;       /* boolean value for override-redirect */
    Screen *screen;               /* back pointer to correct screen */

=head1 METHODS

See parent class L<X11::Xlib::Struct>

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2020 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
