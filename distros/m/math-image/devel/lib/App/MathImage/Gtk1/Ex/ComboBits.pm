# Copyright 2012, 2013 Kevin Ryde

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

package App::MathImage::Gtk1::Ex::ComboBits;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA', '@EXPORT_OK';
$VERSION = 110;

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw(mouse_wheel);

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------

my @button_to_incr;
$button_to_incr[4] = -1;
$button_to_incr[5] = 1;
sub mouse_wheel {
  my ($combo) = @_;
  my $entry = $combo->entry;
  $entry->signal_connect (button_press_event => \&_do_mouse_wheel);
}
sub _do_mouse_wheel {
  my ($entry, $event) = @_;
  ### Combo _do_mouse_wheel(): $event
  my $combo = $entry->parent;
  if ((my $incr = $button_to_incr[$event->{'button'}])
      && (my $list = $combo->list)
      && (my $entry = $combo->entry)) {
    my ($item) = $list->selection;
    if ($item) {
      my $pos = $list->child_position($item);
      ### $pos
      $pos += $incr;
      if ($pos >= 0) {
        $list->select_item($pos);
      }
    }
  }
  return 0; # EVENT_PROPAGATE
}

1;
__END__
