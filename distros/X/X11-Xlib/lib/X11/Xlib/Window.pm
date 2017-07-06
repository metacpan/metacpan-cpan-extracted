package X11::Xlib::Window;
use strict;
use warnings;
use parent 'X11::Xlib::XID';

sub clear_all {
    delete @{$_[0]}{qw( attributes )};
}

sub attributes {
    my $self= shift;
    unless (defined $self->{attributes}) {
        $self->display->XGetWindowAttributes($self, my $struct);
        $self->{attributes}= $struct;
    }
    $self->{attributes}
}

sub get_property_list {
    my $self= shift;
    $self->display->XListProperties($self);
}

sub get_property {
    my ($self, $prop, $type, $offset, $max_length)= @_;
    $type ||= X11::Xlib::AnyPropertyType();
    $offset ||= 0;
    $max_length ||= 1024;
    if (0 == $self->display->XGetWindowProperty($self, $prop, 0, int($max_length/4), 0, $type,
        my $actual_type, my $actual_format, my $n, my $remaining, my $data)
    ) {
        return {
            type => $actual_type,
            format => $actual_format,
            count => $n,
            remaining => $remaining,
            data => $data
        };
    }
    return undef;
}

sub set_property {
    my ($self, $prop, $type, $value, $item_size, $count)= @_;
    if (!defined $type || !defined $value) {
        $self->display->XDeleteProperty($self, $prop);
    } else {
        $item_size ||= 8;
        $count ||= int(length($value)/int($item_size/8));
        $self->display->XChangeProperty($self, $prop, $type, $item_size,
            X11::Xlib::PropModeReplace, $value, $count);
    }
}

sub get_w_h {
    my $self= shift;
    my ($x, $y);
    (undef, undef, undef, $x, $y)
        = $self->display->XGetGeometry($self->xid);
    return ($x, $y);
}

sub show {
    my ($self, $visible)= @_;
    if ($visible || !defined $visible) {
        $self->display->XMapWindow($self->xid);
    } else {
        $self->display->XUnmapWindow($self->xid);
    }
}

sub hide { shift->show(0) }

sub event_mask {
    my $self= shift;
    if (@_) {
        my $mask= 0;
        $mask |= $_ for @_;
        $self->display->XSelectInput($self->xid, $mask);
        $self->{attributes}->your_event_mask($mask)
            if defined $self->{attributes};
    } else {
        $self->attributes->your_event_mask;
    }
}

sub event_mask_include {
    my $self= shift;
    my $mask= 0;
    $mask |= $_ for @_;
    return unless $mask;
    my $old= $self->event_mask;
    return unless ~$old & $mask;
    $self->event_mask($old | $mask);
}

sub event_mask_exclude {
    my $self= shift;
    my $mask= 0;
    $mask |= $_ for @_;
    return unless $mask;
    my $old= $self->event_mask;
    return unless $old & $mask;
    $self->event_mask($old & ~$mask);
}

sub set_bounding_region {
    my ($self, $region, $ofs_x, $ofs_y)= @_;
    $self->display->XFixesSetWindowShapeRegion(
        $self, &X11::Xlib::ShapeBounding, $ofs_x||0, $ofs_y||0, $region||0
    );
}

sub set_input_region {
    my ($self, $region, $ofs_x, $ofs_y)= @_;
    $self->display->XFixesSetWindowShapeRegion(
        $self, &X11::Xlib::ShapeInput, $ofs_x||0, $ofs_y||0, $region||0
    );
}

sub DESTROY {
    my $self= shift;
    $self->display->XDestroyWindow($self->xid)
        if $self->autofree;
}

1;

__END__

=head1 NAME

X11::Xlib::Window - XID wrapper for Window

=head1 SYNOPSIS

  use X11::Xlib;
  my $display = X11::Xlib->new();
  my $window = $display->RootWindow();
  ...

=head1 METHODS

(see L<X11::Xlib::XID> for inherited methods/attributes)

=head2 attributes

Calls L<X11::Xlib/XGetWindowAttributes>, caches the result, and returns
the instance of L<X11::Xlib::XWindowAttributes>.

=head2 clear_all

Clear any cached value of the window so that the next access loads it fresh
from the server.

=head2 event_mask

  my $current_mask= $window->event_mask;
  $window->event_mask( $current_mask | SubstructureRedirectMask );

Get or set the event mask.  Reading this value may return cached data, or else
cause a call to L<XGetWindowAttibutes|X11::Xlib/XGetWindowAttibutes>.
Setting the event mask uses L<XSelectInput|X11::Xlib/XSelectInput>, and
updates the cache.

=head2 event_mask_include

  $window->event_mask_include( @event_masks );

Read the current event mask (unless cached already), then bitwise OR it with
each parameter, then set the mask on the window if anything changed.

=head2 event_mask_exclude

  $window->event_mask_exclude( @event_masks );

Read the current event mask (unless cached already), then bitwise AND NOT with
each parameter, then set the mask on the window if anything changed.

=head2 get_w_h

  my ($w, $h)= $window->get_w_h

Return width and height of the window by calling L<XGetGeometry|X11::Xlib/XGetGeometry>.
This never uses a cache and always returns the current size of the window,
since often it has been altered by window managers etc.

For a cached value, just use C<< $window->attributes->width >> etc.

=head2 show

  $win->show;
  $win->show(1);
  $win->show(0);  # equivalent to 'hide'

Calls L<XMapWindow|X11::Xlib/XMapWindow> to request that the X server display the window.

You can pass a boolean argument to conditionally call L</hide> instead.

=head2 hide

Calls L<XUnmapWindow|X11::Xlib/XUnmapWindow> to request the window be hidden.

=head2 set_bounding_region

  $window->set_bounding_region($region);
  $window->set_bounding_region($region, $x_ofs, $y_ofs);

Set the L<region|X11::Xlib::XserverRegion> for the boundary of the window, optionally
offset by an (x,y) coordinate.  C<$region> may be undef or 0 to un-set the region.

=head2 set_input_region

  $window->set_input_region($region);
  $window->set_input_region($region, $x_ofs, $y_ofs);

Set the input "hit" L<region|X11::Xlib::XserverRegion> of the window, optionally
offset by an (x,y) coordinate. C<$region> may be undef or 0 to un-set the region.

=head1 SEE ALSO

L<X11::Xlib>

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
