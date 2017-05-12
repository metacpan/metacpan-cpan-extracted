# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package App::MathImage::Gtk2::Ex::AdjustmentBits;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2 1.220;
use Gtk2::Ex::AdjustmentBits 46;  # v.46 for scroll_event

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;

sub scroll_widget_ai {
  my ($widget, $event) = @_;
  _scroll_widget_event_props ($widget, $event, 'adjustment', 'inverted');
}

my %scroll_direction_to_vh = (left  => 'h',
                              right => 'h',
                              up    => 'v',
                              down  => 'v');
sub scroll_widget_event_vhi {
  my ($widget, $event) = @_;
  my $vh = $scroll_direction_to_vh{$event->direction};
  _scroll_widget_event_props ($widget, $event,
                              "${vh}adjustment", "${vh}inverted");
}
sub scroll_widget_event_vh {
  my ($widget, $event) = @_;
  my $vh = $scroll_direction_to_vh{$event->direction};
  _scroll_widget_event_props ($widget, $event, "${vh}adjustment");
}

sub _scroll_widget_event_props {
  my ($widget, $event, $adjname, $invname) = @_;
  if (my $adj = $widget->get($adjname)) {
    Gtk2::Ex::AdjustmentBits::scroll_event
        ($adj,
         $event,
         defined $invname && $widget->get_property($invname));
  }
}

1;
__END__

=for stopwords Ryde MathImage scrollbar

=head1 NAME

App::MathImage::Gtk2::Ex::AdjustmentBits -- helpers for Gtk2::Adjustment objects

=head1 SYNOPSIS

 use App::MathImage::Gtk2::Ex::AdjustmentBits;

=head1 FUNCTIONS

...

=head1 SEE ALSO

L<Gtk2::Adjustment>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see L<http://www.gnu.org/licenses/>.

=cut
