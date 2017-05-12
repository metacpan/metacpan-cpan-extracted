# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package App::MathImage::Gtk2::Ex::ToolItem::ComboText::MenuItem;
use 5.008;
use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;

use Glib::Object::Subclass
  'Gtk2::CheckMenuItem',
  signals => { activate => \&_do_activate };

use Gtk2::Ex::MenuItem::Subclass;
our @ISA;
unshift @ISA, 'Gtk2::Ex::MenuItem::Subclass';

sub INIT_INSTANCE {
  my ($self) = @_;
  ### ComboText MenuItem INIT_INSTANCE()...
  $self->set_draw_as_radio(1);
}

sub _do_activate {
  my ($self) = @_;
  ### ComboText MenuItem _do_activate()...
  $self->signal_chain_from_overridden;

  $self->get_active || return;
  my $menuview = _menu_get_ancestor
    ($self, 'App::MathImage::Gtk2::Ex::ToolItem::ComboText::MenuView') || return;
  ### ancestor: "$menuview"
  $menuview->set_active_item ($self);
}


# $menu is either $self or a sub-menu, return the $self MenuView
sub _menu_get_ancestor {
  my ($widget, $target_class) = @_;
  do {
    if ($widget->isa($target_class)) {
      return $widget;
    }
    if ($widget->isa('Gtk2::Menu')) {
      $widget = $widget->get_attach_widget;
    } else {
      $widget = $widget->get_parent;
    }
  } while ($widget);
  ### _menu_get_ancestor() not found...
  return undef;
}

1;
__END__
