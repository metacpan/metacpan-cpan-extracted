package X11::GLX::Pixmap;
$X11::GLX::Pixmap::VERSION = '0.03';
use strict;
use warnings;
use parent 'X11::Xlib::Pixmap';

# ABSTRACT: Object representing a GLX Pixmap


sub x_pixmap { my $self= shift; if (@_) { $_->{x_pixmap}= shift; } $_->{x_pixmap} }

sub DESTROY {
    my $self= shift;
    if ($self->autofree && $self->xid) {
        X11::GLX::glXDestroyGLXPixmap($self->display, $self->xid);
        delete $self->{xid}; # make sure parent constructor doesn't run
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

X11::GLX::Pixmap - Object representing a GLX Pixmap

=head1 VERSION

version 0.03

=head1 DESCRIPTION

GLX Pixmaps are built on top of a normal X pixmap by calling
L<X11::GLX/glXCreateGLXPixmap>, which attaches some buffers needed by OpenGL
and returns a new X11 resource ID.  The pixmap can then be a rendering target.

The pixmap must also be freed with L<X11::GLX/glXDestroyGLXPixmap>, which this
module handles.

=head1 ATTRIBUTES

Extends L<X11::Xlib::Pixmap> with:

=head2 x_pixmap

The X11 pixmap which this GLX pixmap is extending.

This GLX pixmap wrapper holds a reference to the X pixmap to make sure it
isn't destroyed until after the GLX pixmap.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
