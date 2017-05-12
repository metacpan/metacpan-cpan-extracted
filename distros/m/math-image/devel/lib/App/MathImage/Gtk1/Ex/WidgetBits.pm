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

package App::MathImage::Gtk1::Ex::WidgetBits;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA', '@EXPORT_OK';
$VERSION = 110;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(set_usize_until_mapped);

# uncomment this to run the ### lines
#use Devel::Comments;


#------------------------------------------------------------------------------

sub set_usize_until_mapped {
  my ($widget, $width, $height) = @_;
  $widget->signal_connect (map_event => \&_reset_usize);
  $widget->set_usize($width,$height);
}
sub _reset_usize {
  my ($widget) = @_;
  ### _reset_usize: "$widget"
  $widget->set_usize (-1,-1);
}

1;
__END__
