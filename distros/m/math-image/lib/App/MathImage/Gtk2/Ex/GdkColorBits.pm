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

package App::MathImage::Gtk2::Ex::GdkColorBits;
use 5.008;
use strict;
use warnings;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(to_HRRGGBB);

our $VERSION = 110;

sub to_HRRGGBB {
  my ($color) = @_;
  return sprintf ('#%02X%02X%02X',
                  $color->red   >> 8,
                  $color->green >> 8,
                  $color->blue  >> 8);
}

1;
__END__

=for stopwords Ryde color GdkColor Gtk Perl-Gtk Gtk2

=head1 NAME

App::MathImage::Gtk2::Ex::GdkColorBits -- misc GdkColor helpers

=head1 SYNOPSIS

 use App::MathImage::Gtk2::Ex::GdkColorBits;

=head1 FUNCTIONS

=over

=item C<< $str = App::MathImage::Gtk2::Ex::GdkColorBits::to_HRRGGBB ($color) >>

Return a 2-digit hex string like "#FF00AA" for the given
C<Gtk2::Gdk::Color>, with the red, green and blue fields reduced to a range
00 to FF for that result.

See C<< $color->to_string >> for the full 4-digit form (new in Gtk 2.12 and
Perl-Gtk 1.160).

=back

=cut
