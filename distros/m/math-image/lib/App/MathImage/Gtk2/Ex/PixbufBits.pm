# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package App::MathImage::Gtk2::Ex::PixbufBits;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use Scalar::Util;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;


sub filename_to_format {
  my ($filename) = @_;
  return List::Util::first
    { format_matches_filename($_, $filename) }
      Gtk2::Gdk::Pixbuf->get_formats;
}
# $format->{'extensions'} list like ['tiff','tif'] without dots
sub format_matches_filename {
  my ($format, $filename) = @_;
  return List::Util::first
    { $filename =~ /\Q.$_\E$/i }
      @{$format->{'extensions'}};
}

1;
__END__

=for stopwords Ryde pixbuf Gtk Gtk2 PNG Zlib png huffman lzw jpeg lossy JPEG filename PixbufFormat Gtk2-Perl fakery

=head1 NAME

App::MathImage::Gtk2::Ex::PixbufBits -- misc Gtk2::Gdk::Pixbuf helpers

=head1 SYNOPSIS

 use App::MathImage::Gtk2::Ex::PixbufBits;

=head1 FUNCTIONS

=over

=item C<< $format = App::MathImage::Gtk2::Ex::PixbufBits::filename_to_format ($filename) >>

Return the C<Gtk2::Gdk::PixbufFormat> for the given C<$filename> from its
extension.  For example F<foo.png> is PNG format.  If the filename is not
recognised then return C<undef>.

PixbufFormat is new in Gtk 2.2.  Currently C<filename_to_format> throws an
error in Gtk 2.0.x.  Would returning C<undef> be better?  Or some
compatibility fakery?

=item C<< App::MathImage::Gtk2::Ex::PixbufBits::format_matches_filename ($format, $filename) >>

C<$format> should be a C<Gtk2::Gdk::PixbufFormat> object.  Return true if
one of its extensions matches C<$filename>.  For example JPEG format matches
F<foo.jpg> or F<foo.jpeg>.

=back

=cut
