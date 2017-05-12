#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Gtk2::Ex::ComboBox::PixbufType;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

if (0) {
  my @properties = Glib::Object::list_properties('Gtk2::ComboBox');
  require Data::Dumper;
  print Data::Dumper->new([\@properties],['combobox properties'])->Dump;
  exit 0;
}

if (0) {
  my @properties = Glib::Object::list_properties('Gtk2::Ex::ComboBox::PixbufType');
  require Data::Dumper;
  print Data::Dumper->new([\@properties],['savetype properties'])->Dump;
  exit 0;
}


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $combo = Gtk2::Ex::ComboBox::PixbufType->new;
$combo->_configure_types (prefer_list => [ 'png', 'tiff', 'svg' ],
                         plus_formats => [ { name => 'svg' } ]);
print "$progname: combo type initial @{[$combo->get('active-type')//'undef']}\n";
$vbox->pack_start ($combo, 0, 0, 0);
$combo->signal_connect
  ('notify::active' => sub {
     print "$progname: combo active now @{[$combo->get('active')]}\n";
   });
$combo->signal_connect
  ('notify::active-type' => sub {
     print "$progname: combo type now @{[$combo->get('active-type')//'undef']}\n";
   });

{
  my $button = Gtk2::Button->new_with_label ('Set "jpeg"');
  $button->signal_connect (clicked => sub { $combo->set(type => 'jpeg'); });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Set "nosuch"');
  $button->signal_connect (clicked => sub { $combo->set(type => 'nosuch'); });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Set 999');
  $button->signal_connect (clicked => sub { $combo->set_active(999); });
  $vbox->pack_start ($button, 0, 0, 0);
}

$toplevel->show_all;
Gtk2->main;

exit 0;
