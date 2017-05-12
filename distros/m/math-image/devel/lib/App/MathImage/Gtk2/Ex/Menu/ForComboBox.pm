# working ?


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

package App::MathImage::Gtk2::Ex::Menu::ForComboBox;
use 5.008;
use strict;
use warnings;
use Scalar::Util;
use Gtk2;
use Glib::Ex::SignalBits;
use Gtk2::Ex::MenuView;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 110;

use Glib::Object::Subclass
  'Gtk2::Ex::MenuView',
  signals => { 'item-create-or-update' => \&_do_item_create_or_update,
             },
  properties => [ Glib::ParamSpec->object
                   ('combobox',
                    'Combo box object',
                    'Blurb.',
                    'Gtk2::ComboBox',
                    Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('active-nick',
                   'Active nick',
                   'The selected enum value, as its nick.',
                   (eval {Glib->VERSION(1.240);1}
                    ? undef # default
                    : ''),  # no undef/NULL before Perl-Glib 1.240
                   Glib::G_PARAM_READWRITE),
                ];

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;
  ### Enum SET_PROPERTY: $pname, $newval

  if ($pname eq 'combobox') {
    my $combobox = $newval;
    Scalar::Util::weaken (my $weak_self = $self);
    $self->{'combobox_ids'} = $combobox && Glib::Ex::SignalIds->new
      ($combobox,
       $combobox->signal_connect (notify => \&_do_combobox_notify, \$weak_self));
    _update_model($self);
  }
}

sub _do_item_create_or_update {
  my ($self, $item, $model, $path, $iter) = @_;
  my $combobox = $self->{'combobox'};
  if (! $item) {
    $item = Gtk2::CheckMenuItem->new;
    $item->set_draw_as_radio (1);
    my $cellview = Gtk2::CellView->new;
    foreach my $renderer ($combobox->get_cells) {
      $cellview->pack_start ($renderer, 1);
      $cellview->set_cell_data_func ($renderer, \&_do_cell_data);
    }
    $item->add ($cellview);
  }
  my $cellview = $item->get_child;
  $cellview->set_model ($combobox->get_model);
  $cellview->set_displayed_row ($path);
  return $item;
}

sub _do_cell_data {
  my ($self, $renderer, $model, $iter) = @_;
}

sub _do_combobox_notify {
  my ($combobox, $pspec, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  my $pname = $pspec->get_name;
  if ($pname eq 'model') {
    _update_model($self);
  } elsif ($pname eq 'active') {
    _update_active($self);
  }
}

sub _update_model {
  my ($self) = @_;
  my $combobox = $self->{'combobox'};
  my $model = $combobox && $combobox->get_model;
  $self->set (model => $model);
  _update_active ($self);
}
sub _update_active {
  my ($self) = @_;
  my $combobox = $self->{'combobox'};
  my $model = $combobox && $combobox->get_model;
  if (my $active_item = delete $self->{'active_item'}) {
    $active_item->set_active (0);
  }
  if (my $iter = $combobox->get_active_iter) {
    my $path = $model->get_path ($iter);
    my $item = $self->item_at_path ($path);
    $item->set_active (1);
    Scalar::Util::weaken ($self->{'active_item'} = $item);
  }
}

1;
__END__

# =for stopwords Math-Image enum ParamSpec pspec Enum Ryde
#
# =head1 NAME
#
# App::MathImage::Gtk2::Ex::Menu::ForComboBox -- menu of entries from a combobox
#
# =head1 SYNOPSIS
#
#  use App::MathImage::Gtk2::Ex::Menu::ForComboBox;
#  my $menu = App::MathImage::Gtk2::Ex::Menu::ForComboBox->new
#               (combobox => $my_combobox);
#
# =head1 WIDGET HIERARCHY
#
# C<App::MathImage::Gtk2::Ex::Menu::ForComboBox> is a subclass of C<Gtk2::Menu>,
#
#     Gtk2::Widget
#       Gtk2::Container
#         Gtk2::MenuShell
#           Gtk2::Menu
#             App::MathImage::Gtk2::Ex::Menu::ForComboBox
#
# =head1 DESCRIPTION
#
# =head1 FUNCTIONS
#
# =over 4
#
# =item C<< $menu = App::MathImage::Gtk2::Ex::Menu::ForComboBox->new (key=>value,...) >>
#
# Create and return a new C<ForComboBox> menu object.  Optional key/value pairs
# set initial properties per C<< Glib::Object->new >>.
#
#     my $menu = App::MathImage::Gtk2::Ex::Menu::ForComboBox->new
#                  (combobox => $my_combobox);
#
# =back
#
# =head1 PROPERTIES
#
# =over 4
#
# =item C<combobox> (C<Gtk2::ComboBox> object, default C<undef>)
#
# =back
#
# =head1 SEE ALSO
#
# L<Gtk2::Menu>,
# L<Gtk2::ComboBox>,
#
# =head1 HOME PAGE
#
# L<http://user42.tuxfamily.org/math-image/index.html>
#
# =head1 LICENSE
#
# Copyright 2010, 2011, 2012, 2013 Kevin Ryde
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# Math-Image.  If not, see L<http://www.gnu.org/licenses/>.
#
# =cut
