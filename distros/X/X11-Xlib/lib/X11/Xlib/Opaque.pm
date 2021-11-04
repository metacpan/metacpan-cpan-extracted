package X11::Xlib::Opaque;
use X11::Xlib ();

# All modules in dist share a version
our $VERSION = '0.23';

@X11::Xlib::Visual::ISA= ( __PACKAGE__ );
$X11::Xlib::Visual::VERSION= $VERSION;
@X11::Xlib::GC::ISA= ( __PACKAGE__ );
$x11::Xlib::GC::VERSION= $VERSION;

1;
__END__

=head1 NAME

X11::Xlib::Opaque - Base class for X11 opaque structures

=head1 DESCRIPTION

Base class for the various hidden C-structs of Xlib, which are represented
as a blessed opaque perl scalar, or blessed perl Hashref with the pointer
tucked away in XS magic.

=head1 ATTRIBUTES

=head2 display

Find the display associated with this object.  This may return undef if the
opaque object was constructed from a source where the Display was unknown.
(for example, accessing the L<X11::Xlib::XVisualInfo/visual> when that struct
itself doesn't have a known Display.

The storage for this attribute is contained in XS, and is a strong reference
to the Display, which is released during the XS destructor for this object.

=head2 pointer_bytes

Return the raw pointer as a string of bytes (i.e. length 8 for 64-bit)

=head2 pointer_int

Return the raw pointer value as an integer

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
