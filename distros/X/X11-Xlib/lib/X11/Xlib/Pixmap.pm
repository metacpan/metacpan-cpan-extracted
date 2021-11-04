package X11::Xlib::Pixmap;
use strict;
use warnings;
use Carp;
use parent 'X11::Xlib::XID';

# All modules in dist share a version
our $VERSION = '0.23';

sub width  { croak "read-only" if @_ > 1; $_[0]{width} }
sub height { croak "read-only" if @_ > 1; $_[0]{height} }
sub depth  { croak "read-only" if @_ > 1; $_[0]{depth} }

sub get_w_h { croak "read-only" if @_ > 1; $_[0]{width}, $_[0]{height} }

sub DESTROY {
    my $self= shift;
    $self->display->XFreePixmap($self->xid)
        if $self->autofree && $self->xid;
}

1;

__END__

=head1 NAME

X11::Xlib::Pixmap - XID wrapper for Pixmap

=head1 DESCRIPTION

Object representing a Pixmap remote X11 resource.

There doesn't seem to be any way to query the attributes of a pixmap,
so this object's attributes must be passed to the constructor.

=head1 ATTRIBUTES

See L<X11::Xlib::XID> for base-class attributes.

=head2 width

Width, in pixels

=head2 height

Height, in pixels

=head2 depth

Color depth, in bits.

=head1 METHODS

=head2 get_w_h

  my ($w, $h)= $pixmap->get_w_h

Reutrn the width and height of the pixmap as a list

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
