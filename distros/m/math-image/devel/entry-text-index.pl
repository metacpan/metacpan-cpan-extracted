#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-Image is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


use 5.010;
use strict;
use warnings;
use Glib::Ex::ConnectProperties;

use Gtk2 '-init';
use Gtk2::Ex::ComboBox::Enum;
use Gtk2::Ex::EntryBits 46; # v.46 for scroll_number_handler()

use Smart::Comments;


use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $entry = Gtk2::Entry->new;
$entry->set_width_chars (10);

my $font_desc = Pango::FontDescription->from_string("Courier 50");
$entry->modify_font ($font_desc);
$entry->signal_connect
  (scroll_event => \&Gtk2::Ex::EntryBits::scroll_number_handler);
$vbox->pack_start ($entry, 0,0,0);

{
  my $label = Gtk2::Label->new;
  $vbox->pack_start ($label, 0,0,0);
  my $update_label = sub {
    my ($entry, $x) = @_;
    my $index = Gtk2::Ex::EntryBits::x_to_text_index($entry,$x);
    $label->set_text ("index = ". ($index // 'undef'));
  };
  $entry->signal_connect
    (motion_notify_event => sub {
       my ($entry, $event) = @_;
       $update_label->($entry,$event->x);
     });
  $entry->signal_connect
    ('notify::text' => sub {
       my ($entry) = @_;
       my ($x, $y) = $entry->get_pointer;
       $update_label->($entry,$x);
     });
}

{
  my $combo = Gtk2::Ex::ComboBox::Enum->new
    (enum_type => 'Gtk2::TextDirection');
  Glib::Ex::ConnectProperties->new
      ([$entry, 'widget#direction'],
       [$combo, 'active-nick']);
  $vbox->pack_start ($combo, 0, 0, 0);

  $entry->signal_connect
    ('direction-changed' => sub {
       my ($entry) = @_;
       print "entry direction: ",$entry->get_direction,"\n";
     });
}

{
  my $pname = 'xalign';
  my $pspec = $entry->find_property ($pname);
  my $adj = Gtk2::Adjustment->new (0,
                                   $pspec->get_minimum,
                                   $pspec->get_maximum,
                                   .05, # step
                                   .5,  # page
                                   0);
  ### min: $pspec->get_minimum
  ### max: $pspec->get_maximum
  my $hbox = Gtk2::HBox->new;
  $vbox->pack_start ($hbox, 0,0,0);
  $hbox->pack_start (Gtk2::Label->new($pname), 0,0,0);
  my $spin = Gtk2::SpinButton->new ($adj,
                                    .05,  # climb
                                    2);   # digits
  $hbox->pack_start ($spin, 1,1,0);
  Glib::Ex::ConnectProperties->new ([$entry,$pname],
                                    [$spin,'value']);
}

# {
#   my $button = Gtk2::CheckButton->new_with_label ('Toolitem Sensitive');
#   require Glib::Ex::ConnectProperties;
#   Glib::Ex::ConnectProperties->new
#       ([$toolitem, 'sensitive'],
#        [$button, 'active']);
#   $button->show;
#   $vbox->pack_start ($button, 0, 0, 0);
# }
# {
#   my $button = Gtk2::CheckButton->new_with_label ('Child Sensitive');
#   Glib::Ex::ConnectProperties->new
#       ([$combobox, 'sensitive'],
#        [$button, 'active']);
#   $button->show;
#   $vbox->pack_start ($button, 0, 0, 0);
# }

$entry->set_text ("ab123cd");
$toplevel->show_all;
Gtk2->main;
exit 0;

