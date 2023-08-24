package X11::Xlib::Window;
use strict;
use warnings;
use parent 'X11::Xlib::XID';

# All modules in dist share a version
our $VERSION = '0.25';

=head1 NAME

X11::Xlib::Window - XID wrapper for Window

=head1 SYNOPSIS

  use X11::Xlib;
  my $display = X11::Xlib->new();
  my $window = $display->RootWindow();
         ... = $display->get_cached_window(1234);

=head1 METHODS

(see L<X11::Xlib::XID> for inherited methods/attributes)

=head2 attributes

Calls L<X11::Xlib/XGetWindowAttributes>, caches the result, and returns
the instance of L<X11::Xlib::XWindowAttributes>.

=head2 clear_all

Clear any cached value of the window so that the next access loads it fresh
from the server.

=cut

sub attributes {
    my $self= shift;
    unless (defined $self->{attributes}) {
        $self->display->XGetWindowAttributes($self, my $struct);
        $self->{attributes}= $struct;
    }
    $self->{attributes}
}

sub clear_all {
    delete @{$_[0]}{qw( attributes )};
}

=head2 get_property_list

  for ($window->get_property_list) { ... }

Returns a list of all properties available on the window.  Each property is an C<atom> dualvar
that stringifies as the property name but can be passed to functions that expect the ID.

=head2 get_property

  $window->get_property($prop_atom);
  $window->get_property($prop_atom, $type_atom, $offset, $max_len);

  # {
  #   type => $atom,   # actual type of property
  #   count => 1,      # number of elements in multi-values property
  #   format => $n,    # 8/16/32 meaning 'char','short','long'
  #   remaining => $n, # bytes unread
  #   data => $bytes,  # payload, needs unpack()ed except for strings
  # }

Return a hashref describing a property, or undef if the property does not exist.

=cut

sub get_property_list {
    my $self= shift;
    $self->display->atom($self->display->XListProperties($self));
}

sub get_property {
    my ($self, $prop, $type, $offset, $max_length)= @_;
    $type ||= X11::Xlib::AnyPropertyType();
    $type= $self->display->atom($type) or Carp::croak("No such type '$type'")
        if !X11::Xlib::_is_an_integer($type);
    $prop= $self->display->atom($prop) or Carp::croak("No such property '$prop'")
        unless X11::Xlib::_is_an_integer($prop);
    my $actual_type;
    if (0 == $self->display->XGetWindowProperty($self, $prop, $offset || 0, $max_length || 65536,
        0, $type, $actual_type, my $actual_format, my $n, my $remaining, my $data)
        and $actual_type # actual_format=0 means property does not exist
    ) {
        return {
            type => $self->display->atom($actual_type),
            format => $actual_format,
            count => $n,
            remaining => $remaining,
            data => $data
        };
    }
    return undef;
}

=head2 get_decoded_property

  my $prop= $window->get_decoded_property($prop_atom);
                ...->get_decoded_property($prop_atom, $type_atom);

This fetches a property and attempts to decode it into the best Perl representation.
If the returned type is not known this throws an exception; you'll have to use C<get_property>
and decode it yourself.

For strings, this returns a single scalar.  For decoded objects, this returns one object
or an arrayref of objects.  So, you always get one return value, or undef.

For conveniently unrolling this into list context, use C<get_decoded_property_items>.

=head2 get_decoded_property_items

  my @items= $window->get_decoded_property_items($prop_atom, $type_atom=Any);
  
  # Example: dump out all properties of the window
  for my $prop ($window->get_property_list) {
    eval { say join " ", $prop, "=", $window->get_decoded_property_items($prop); }
      or say "$prop: Cant decode ".$window->get_property($prop)->{type};
  }

The return value is a list, since many properties are multi-value but many are single-value,
and there's no good way to know which properties are intended as arrays with one element.

=cut

sub get_decoded_property_items {
    my ($self, $prop, $type)= @_;
    $type ||= X11::Xlib::AnyPropertyType();
    $type= $self->display->atom($type) or Carp::croak("No such type '$type'")
        if !X11::Xlib::_is_an_integer($type);
    $prop= $self->display->atom($prop) or Carp::croak("No such property '$prop'")
        if !X11::Xlib::_is_an_integer($prop);
    my ($offset, $actual_type, $actual_format, $n, $remaining, $data);
    return undef if 0 != $self->display->XGetWindowProperty($self, $prop, 0, 65536, 0, $type,
            $actual_type, $actual_format, $n, $remaining, $data)
            or !$actual_type;
    while ($remaining) {
        $offset += 65536;
        last unless 0 == $self->display->XGetWindowProperty(
            $self, $prop, $offset, 65536, 0, $type,
            $actual_type, $actual_format, my $n2, $remaining, my $data2
        );
        $data .= $data2;
        $n += $n2;
    }
    $actual_type= $self->display->atom($actual_type);
    my $dec= $self->can("_decode_prop_$actual_type")
        or Carp::croak("No decoder for type '$actual_type'");
    $self->$dec($data, $n, $actual_format);
}

sub get_decoded_property {
    my @ret= shift->get_decoded_property_items(@_);
    return @ret == 1? $ret[0] : \@ret;
}

sub _decode_prop_STRING { # ($self, $data, $n, $format)
    return $_[1];
}
sub _encode_prop_STRING {
    my $str= $_[1];
    utf8::downgrade($str);
    return ( $str, length $str, 8 );
}

sub _decode_prop_UTF8_STRING { # ($self, $data, $n, $format)
    utf8::decode($_[1]);
    return $_[1];
}
sub _encode_prop_UTF8_STRING {
    my $str= $_[1];
    utf8::encode($str);
    return ( $str, length $str, 8 );
}

my $long_pack= X11::Xlib::_prop_format_width(32) == 4? 'l*' : 'q*';
my $ulong_pack= uc($long_pack);

sub _decode_prop_INTEGER { # ($self, $data, $n, $format)
    my ($self, undef, $n, $format)= @_;
    X11::Xlib::_unpack_prop_signed $format, $_[1], $n;
}
sub _encode_prop_INTEGER {
    my $self= shift;
    return ( pack($long_pack, @_), scalar @_, 32 );
}

sub _decode_prop_CARDINAL { # ($self, $data, $n, $format)
    my ($self, undef, $n, $format)= @_;
    X11::Xlib::_unpack_prop_unsigned $format, $_[1], $n;
}
sub _encode_prop_CARDINAL {
    my $self= shift;
    return ( pack($long_pack, @_), scalar @_, 32 );
}

sub _decode_prop_ATOM { # ($self, $data, $n, $format)
    $_[0]->display->atom(_decode_prop_CARDINAL(@_));
}
sub _encode_prop_ATOM {
    my $self= shift;
    my @atoms= map +($_? (0+$_) : ()), $self->display->atom(@_);
    return ( pack($long_pack, @atoms), scalar @atoms, 32 );
}

sub _decode_prop_WINDOW { # ($self, $data, $n, $format)
    map $_[0]->display->get_cached_window($_), _decode_prop_CARDINAL(@_);
}
sub _encode_prop_WINDOW {
    my $self= shift;
    my @xid= map +(ref $_? $_->xid : 0+$_), @_;
    return ( pack($long_pack, @xid), scalar @xid, 32 );
}

sub _decode_prop_PIXMAP { # ($self, $data, $n, $format)
    map $_[0]->display->get_cached_pixmap($_), _decode_prop_CARDINAL(@_);
}
*_encode_prop_PIXMAP = *_encode_prop_WINDOW;

=head2 set_property

  $window->set_property($prop_atom, $type_atom, $data, $format, $count);
  $window->set_property($prop_atom, $type_atom, \@value); # for known types
  $window->set_property($prop_atom, undef);  # delete the property

In the first form, the parameters basically just go to L<X11::Xlib/XChangeProperty>
after supplying defaults for size and count.  C<$item_size> must be 8, 16, or 32
(which means 'long' regardless of whether C<long> is 32 bits), and count can be
given or derived from the length of C<$data>.

In the second form, a known C<$type_atom> may have special support for encoding an
array of arguments.  The arguments must be given in an array to indicate the user
wants some support in packing them.

In the third form, undefined type results in the deletion of the property.

=cut

sub set_property {
    my ($self, $prop, $type, $val, $format, $count)= @_;
    return $self->display->XDeleteProperty($self, $prop)
        unless defined $type || defined $val;
    $type= $self->display->atom($type) || Carp::croak("No such type $type");

    if ($format || $count) { # user provided format and/or count
        my $w= X11::Xlib::_prop_format_width($format)
            or Carp::croak("Unknown format $format");
        if (ref $val eq 'ARRAY') {
            $count ||= @$val;
            $val= pack($w == 1? 'C*' : $w == 2? 'S*' : $w == 4? 'L*' : 'Q*', @{$val}[0 .. ($count-1)]);
        } else {
            $count ||= int(length($val) / $w);
            length($val) >= $w * $count
                or Carp::croak("Buffer too short for $count items of $w bytes");
        }
    } elsif (ref $val ne 'HASH') {
        my $enc= $self->can('_encode_prop_'.$type)
            or Carp::croak("No encoder for type '$type'");
        ($val, $count, $format)= $self->$enc(ref $val eq 'ARRAY'? @$val : $val);
    }
    $self->display->XChangeProperty($self, $prop, $type, $format,
        X11::Xlib::PropModeReplace, $val, $count);
}

=head2 get_w_h

  my ($w, $h)= $window->get_w_h

Return width and height of the window by calling L<XGetGeometry|X11::Xlib/XGetGeometry>.
This never uses a cache and always returns the current size of the window,
since often it has been altered by window managers etc.

For a cached value, just use C<< $window->attributes->width >> etc.

=cut

sub get_w_h {
    my $self= shift;
    my ($x, $y);
    (undef, undef, undef, $x, $y)
        = $self->display->XGetGeometry($self->xid);
    return ($x, $y);
}

=head2 show

  $win->show;
  $win->show(1);
  $win->show(0);  # equivalent to 'hide'

Calls L<XMapWindow|X11::Xlib/XMapWindow> to request that the X server display the window.

You can pass a boolean argument to conditionally call L</hide> instead.

=head2 hide

Calls L<XUnmapWindow|X11::Xlib/XUnmapWindow> to request the window be hidden.

=cut

sub show {
    my ($self, $visible)= @_;
    if ($visible || !defined $visible) {
        $self->display->XMapWindow($self->xid);
    } else {
        $self->display->XUnmapWindow($self->xid);
    }
}

sub hide { shift->show(0) }

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

=cut

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

=head2 set_bounding_region

  $window->set_bounding_region($region);
  $window->set_bounding_region($region, $x_ofs, $y_ofs);

Set the L<region|X11::Xlib::XserverRegion> for the boundary of the window, optionally
offset by an (x,y) coordinate.  C<$region> may be undef or 0 to unset the region.

=head2 set_input_region

  $window->set_input_region($region);
  $window->set_input_region($region, $x_ofs, $y_ofs);

Set the input "hit" L<region|X11::Xlib::XserverRegion> of the window, optionally
offset by an (x,y) coordinate. C<$region> may be undef or 0 to unset the region.

=cut

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

=head1 SEE ALSO

L<X11::Xlib>

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
