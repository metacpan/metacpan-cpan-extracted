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

package App::MathImage::Gtk2::Ex::ToolItem::ComboText::MenuView;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Gtk2::Ex::MenuView 4; # v.4 for item_get_path()
use App::MathImage::Gtk2::Ex::ToolItem::ComboText::MenuItem;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;

use Glib::Object::Subclass
  'Gtk2::Ex::MenuView',
  signals => { item_create_or_update => \&_do_item_create_or_update };

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set (want_activate => 'no');
}

sub _do_item_create_or_update {
  my ($self, $item, $model, $path, $iter) = @_;
  ### ComboText MenuView _do_item_create_or_update(): "path=".$path->to_string
  my $str = $model->get ($iter, 0);
  if ($item) {
    $item->get_child->set_text ($str);
  } else {
    $item = App::MathImage::Gtk2::Ex::ToolItem::ComboText::MenuItem->new_with_label ($str);
  }
  return $item;
}

# from combobox change
sub set_active_iter {
  my ($self, $iter) = @_;
  ### ComboText-MenuView set_active_iter()...

  my $model;
  my $path = $iter
    && ($model = $self->get('model'))
      && $model->get_path($iter);
  $self->set_active_path($path);
}
sub set_active_path {
  my ($self, $path) = @_;
  #  $self->_current_item_at_path($path)
  $self->set_active_item ($self->item_at_path ($path));
}

# from item activate
sub set_active_item {
  my ($self, $item) = @_;
  ### ComboText-MenuView set_active_item(): defined $item && $item->get_child->get_text
  ###   old item: defined $self->{'active_item'} && $self->{'active_item'}->get_child->get_text

  # watch out for recurse from combobox 'changed' handler
  my $old_item = $self->{'active_item'};
  if (($old_item||0) == ($item||0)) {
    ### unchanged: ($old_item||0).'', ($item||0).''
    return;
  }
  Scalar::Util::weaken ($self->{'active_item'} = $item);

  if ($old_item) {
    $old_item->set_active (0);
  }
  if ($item) {
    $item->set_active (1);
  }
  if (my $toolitem = $self->{'toolitem'}) {
    if (my $combobox = $toolitem->get_child) {
      Gtk2::Ex::ComboBoxBits::set_active_path
          ($combobox, $item && $self->item_get_path($item));
    }
  }
}

1;
__END__
