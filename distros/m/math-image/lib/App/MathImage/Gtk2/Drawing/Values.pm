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


package App::MathImage::Gtk2::Drawing::Values;
use 5.008;
use strict;
use warnings;
use App::MathImage::Generator;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;
our $TEXTDOMAIN = 'App-MathImage';
Glib::Type->register_enum ('App::MathImage::Gtk2::Drawing::Values',
                           App::MathImage::Generator->values_choices);

# Don't load up all classes for the combobox ...
# sub EnumBits_to_display {
#   my ($class, $nick) = @_;
#   require App::MathImage::Generator;
#   return App::MathImage::Generator->values_class($nick)->name;
# }

sub EnumBits_to_description {
  my ($class, $nick) = @_;
  require App::MathImage::Generator;
  return App::MathImage::Generator->values_class($nick)->description;
}

1;
__END__
