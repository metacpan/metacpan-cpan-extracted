package X11::Xlib::Colormap;
use strict;
use warnings;
use parent 'X11::Xlib::XID';

# All modules in dist share a version
our $VERSION = '0.23';

sub DESTROY {
    my $self= shift;
    $self->display->XFreeColormap($self->xid)
        if $self->autofree;
}

1;

__END__

=head1 NAME

X11::Xlib::Colormap - XID wrapper for Colormap

=head1 DESCRIPTION

Object representing a Colormap, which is a remote X11 resource
referenced by an XID.  When this object goes out of scope it calls
L<XDestroyColormap|X11::Xlib/XDestroyColormap> if L<autofree|X11::Xlib::XID/autofree>
is true.

=head1 ATTRIBUTES

See L<X11::Xlib::XID>

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
