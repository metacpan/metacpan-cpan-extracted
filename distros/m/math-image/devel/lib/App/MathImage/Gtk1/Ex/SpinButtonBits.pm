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

package App::MathImage::Gtk1::Ex::SpinButtonBits;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA', '@EXPORT_OK';
$VERSION = 110;

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw(mouse_wheel);

# uncomment this to run the ### lines
#use Devel::Comments;


#------------------------------------------------------------------------------

my @button_to_direction;
$button_to_direction[4] = 'up';
$button_to_direction[5] = 'down';
sub mouse_wheel {
  my ($spin) = @_;
  $spin->signal_connect (button_press_event => \&_do_mouse_wheel);
}
sub _do_mouse_wheel {
  my ($spin, $event) = @_;
  ### spin _do_mouse_wheel(): $event
  if ((my $direction = $button_to_direction[$event->{'button'}])
      && (my $adj = $spin->get_adjustment)) {
    $spin->spin ($direction,
                 $event->{'state'} & 4 # 'control-mask'
                 ? $adj->page_increment : $adj->step_increment);
  }
  return 0; # EVENT_PROPAGATE
}

1;
__END__
