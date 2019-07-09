# Copyright 2010, 2011, 2012, 2013, 2014, 2017, 2019 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

package X11::Protocol::Other;
use 5.004;
use strict;
use Carp;
use X11::AtomConstants;

use vars '$VERSION', '@ISA', '@EXPORT_OK';
$VERSION = 31;

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw(root_to_screen
                root_to_screen_info
                default_colormap_to_screen
                default_colormap_to_screen_info
                visual_is_dynamic
                visual_class_is_dynamic
                window_size
                window_visual
                get_property_atoms
                hexstr_to_rgb
              );

# uncomment this to run the ### lines
#use Smart::Comments;

sub window_size {
  my ($X, $window) = @_;
  ### Other window_size(): "$X $window"
  my $screen_info;
  if ($screen_info = root_to_screen_info($X,$window)) {
    return ($screen_info->{'width_in_pixels'},
            $screen_info->{'height_in_pixels'});
  }
  my %geom = $X->GetGeometry ($window);
  return ($geom{'width'}, $geom{'height'});
}
sub window_visual {
  my ($X, $window) = @_;
  ### Other window_visual(): "$X $window"
  my $screen_info;
  if ($screen_info = root_to_screen_info($X,$window)) {
    return $screen_info->{'root_visual'};
  }
  my %attr = $X->GetWindowAttributes ($window);
  return $attr{'visual'};
}

#------------------------------------------------------------------------------

sub root_to_screen {
  my ($X, $root) = @_;
  ### Other root_to_screen(): $root
  return ($X->{__PACKAGE__.'.root_to_screen_number'}
          ||= { map {($X->{'screens'}->[$_]->{'root'} => $_)}
                0 .. $#{$X->{'screens'}} })
    ->{$root};
}
sub root_to_screen_info {
  my ($X, $root) = @_;
  ### Other root_to_screen_info(): $root
  my $ret;
  if (defined ($ret = root_to_screen($X,$root))) {
    $ret = $X->{'screens'}->[$ret];
  }
  return $ret;

  # return ($X->{__PACKAGE__.'.root_to_screen_info'}
  #         ||= { map {($_->{'root'} => $_)} @{$X->{'screens'}} })->{$root}
}

#------------------------------------------------------------------------------

sub default_colormap_to_screen {
  my ($X, $colormap) = @_;
  ### default_colormap_to_screen(): $colormap
  return ($X->{__PACKAGE__.'.default_colormap_to_screen_number'}
          ||= { map {($X->{'screens'}->[$_]->{'default_colormap'} => $_)}
                0 .. $#{$X->{'screens'}} })
    ->{$colormap};
}
sub default_colormap_to_screen_info {
  my ($X, $colormap) = @_;
  ### Other colormap_to_screen_info(): $colormap
  my $ret;
  if (defined ($ret = default_colormap_to_screen($X,$colormap))) {
    $ret = $X->{'screens'}->[$ret];
  }
  return $ret;
}

# # return true if $colormap is one of the screen default colormaps
# sub colormap_is_default {
#   my ($X, $colormap) = @_;
#   return defined (default_colormap_to_screen($X,$colormap));
# }


#------------------------------------------------------------------------------
# my %visual_class_is_dynamic = (StaticGray  => 0,  0 => 0,
#                                GrayScale   => 1,  1 => 1,
#                                StaticColor => 0,  2 => 0,
#                                PseudoColor => 1,  3 => 1,
#                                TrueColor   => 0,  4 => 0,
#                                DirectColor => 1,  5 => 1,
#                               );
sub visual_class_is_dynamic {
  my ($X, $visual_class) = @_;
  return $X->num('VisualClass',$visual_class) & 1;
}
sub visual_is_dynamic {
  my ($X, $visual_id) = @_;
  my $visual_info = $X->{'visuals'}->{$visual_id}
    || croak 'Unknown visual ',$visual_id;
  return visual_class_is_dynamic ($X, $visual_info->{'class'});
}

#------------------------------------------------------------------------------

# cf XcmsLRGB_RGB_ParseString() in XcmsLRGB.c

sub hexstr_to_rgb {
  my ($str) = @_;
  ### hexstr_to_rgb(): $str
  # Crib: [:xdigit:] is new in 5.6, so only 0-9A-F
  $str =~ /^#(([0-9A-F]{3}){1,4})$/i or return;
  my $len = length($1)/3; # of each group, so 1,2,3 or 4
  return (map {hex(substr($_ x 4, 0, 4))}  # first 4 chars of replicated
          substr ($str, 1, $len),      # full groups
          substr ($str, 1+$len, $len),
          substr ($str, -$len));
}

# my %hex_factor = (1 => 0x1111,
#                   2 => 0x101,
#                   3 => 0x10 + 1/0x100,
#                   4 => 1);
#   my $factor = $hex_factor{$len} || return;
#   ### $len
#   ### $factor


#------------------------------------------------------------------------------

sub get_property_atoms {
  my ($X, $window, $property) = @_;
  (my $value,
   undef,            # type
   my $format,
   my $bytes_after)
    = $X->GetProperty ($window, $property,
                       X11::AtomConstants::ATOM(), # type
                       0,          # offset
                       0x7FFFFFFF, # long-length: CARD32, unlimited
                       0);         # delete
  ### $value
  ### $format
  $format == 32 or return;  # not atoms
  if ($bytes_after) {
    croak "oops, extremely long property, has $bytes_after more";
  }
  return unpack('L*', $value);
}

sub set_property_atoms {
  my $X = shift;
  my $window = shift;
  my $property = shift;
  $X->ChangeProperty($window,
                     $property,                   # property
                     X11::AtomConstants::ATOM(),  # type
                     32,                          # format
                     'Replace',
                     pack('L*',@_));
}

# sub set_property_atom_names {
#   my ($X, $window, $property, @atoms) = @_;
#   # ENHANCE-ME: might like to intern all atoms in one round-trip, or perhaps
#   # that's better left to a single big pre-fill of atoms in mainline code
#   set_property_atoms($X,$window,$property,
#                      map {$X->atom($_)} @atoms);
# }


#------------------------------------------------------------------------------

# # return true if $pixel is black or white in the default root window colormap
# sub pixel_is_black_or_white {
#   my ($X, $pixel) = @_;
#   return ($pixel == $X->{'black_pixel'} || $pixel == $X->{'white_pixel'});
# }
# 

1;
__END__

=for stopwords Ryde XID colormap colormaps ie PseudoColor VisualClass RGB rgb 0xFFFF FFF FFFF Xcms recognised unrecognised recognising

=head1 NAME

X11::Protocol::Other -- miscellaneous X11::Protocol helpers

=head1 SYNOPSIS

 use X11::Protocol::Other;

=head1 DESCRIPTION

This is some helper functions for C<X11::Protocol>.

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use X11::Protocol::Other 'visual_is_dynamic';
    if (visual_is_dynamic ($X, $visual_id)) {
      ...
    }

Or just called with full package name

    use X11::Protocol::Other;
    if (X11::Protocol::Other::visual_is_dynamic ($X, $visual_id)) {
      ...
    }

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

=head1 FUNCTIONS

=head2 Screen Finding

=over 4

=item C<$number = root_to_screen ($X, $root)>

=item C<$hashref = root_to_screen_info ($X, $root)>

Return the screen number or screen info hash for a given root window.
C<$root> can be any XID integer on C<$X>.  If it's not one of the root
windows then the return is C<undef>.

=item C<$number = default_colormap_to_screen ($X, $colormap)>

=item C<$hashref = default_colormap_to_screen_info ($X, $colormap)>

Return the screen number or screen info hash for a given default colormap.
C<$colormap> can be any XID integer on C<$X>.  If it's not one of the screen
default colormaps then the return is C<undef>.

=back

=head2 Visuals

=over

=item C<$bool = visual_is_dynamic ($X, $visual_id)>

=item C<$bool = visual_class_is_dynamic ($X, $visual_class)>

Return true if the given visual is dynamic, meaning colormap entries on it
can be changed to change the colour of a given pixel value.

C<$visual_id> is one of the visual ID numbers, ie. one of the keys in
C<$X-E<gt>{'visuals'}>.  Or C<$visual_class> is a VisualClass string like
"PseudoColor" or corresponding integer such as 3.

=back

=head2 Window Info

=over

=item C<($width, $height) = window_size ($X, $window)>

=item C<$visual_id = window_visual ($X, $window)>

Return the size or visual ID of a given window.

C<$window> is an integer XID on C<$X>.  If it's one of the root windows then
the return values are from the screen info hash in C<$X>, otherwise the
server is queried with C<GetGeometry()> (for the size) or
C<GetWindowAttributes()> (for the visual).

These functions are handy when there's a good chance C<$window> might be a
root window and therefore not need a server round trip.

=item C<@atoms = get_property_atoms($X, $window, $property)>

Get from C<$window> (integer XID) a list-of-atoms property C<$property>
(atom integer).  The return is a list of atom integers, possibly an empty
list.  If C<$property> doesn't exist or is not atoms then return an empty
list.

=item C<set_property_atoms($X, $window, $property, @atoms)>

Set on C<$window> (integer XID) a list-of-atoms property C<$property> (atom
integer) as the given list of C<@atoms> (possibly empty).

=back

=head2 Colour Parsing

=over

=item C<($red16, $green16, $blue16) = hexstr_to_rgb($str)>

Parse a given RGB colour string like "#FF00FF" into 16-bit red, green, blue
components.  The return values are always in the range 0 to 65535.  The
strings recognised are 1, 2, 3 or 4 digit hex.

    #RGB
    #RRGGBB
    #RRRGGGBBB
    #RRRRGGGGBBBB

If C<$str> is unrecognised then the return is an empty list, so for instance

    my @rgb = hexstr_to_rgb($str)
      or die "Unrecognised colour: $str";

The digits of the 1, 2 and 3 forms are replicated as necessary to give a
16-bit range.  For example 3-digit style "#321FFF000" gives return values
0x3213, 0xFFFF, 0.  Or 1-digit "#F0F" is 0xFFFF, 0, 0xFFFF.  Notice "F"
expands to 0xFFFF so an "F", "FF" or "FFF" all mean full saturation the same
as a 4-digit "FFFF".

Would it be worth recognising the Xcms style "rgb:RR/GG/BB"?  Perhaps that's
best left to full Xcms, or general colour conversion modules.  The X11R6
X(7) man page describes the "rgb:" form, but just "#" is much more common.

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::GrabServer>

L<Color::Library> (many named colours), L<Convert::Color>,
L<Graphics::Color> (Moose based) for more colour parsing

L<X11::AtomConstants>,
L<X11::CursorFont>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2017, 2019 Kevin Ryde

X11-Protocol-Other is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

X11-Protocol-Other is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut
