# Copyright 2011, 2012, 2013 Kevin Ryde

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


package App::MathImage::Tk::Perl::WidgetBits;
use 5.008;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = ('with_underline');

our $VERSION = 110;

# =item C<($str, -underline =E<gt> $pos) = with_underline($str)>
#
# This function is designed for use on a C<-label> or C<-text> argument such
# as
#
#     $menu->command (-label => with_underline("_File"),
#                     -command => ...)
#
# If C<$str> has an underscore like S<"Save _As"> then return 3 values
#
#     "Save As", -underline => 5
#
# so the underscore becomes a C<-underline> position.
# If C<$str> doesn't have an underscore then return C<$str> unchanged.
#
# A literal underscore can be included by doubling it, for example
#
#     "Literal__Underscore"
#     # gives "Literal_Underscore"
#
# Extracting an underline position from a string like this is easier than
# counting characters manually for the C<-underline> argument.  It's also
# easier if translating labels into other languages (C<Locale::TextDomain>
# or similar) since the underline position will be different in a different
# language, or there might be no underline at all.

sub with_underline {
  my ($str) = @_;
  my @underline;
  $str =~ s{_(.)}{
    ### $1
    if ($1 ne '_') {
      @underline = (-underline => pos($str)||0);
    }
    $1
  }ge;
  ### $str
  ### @underline
  return ($str, @underline);
}

1;
__END__
