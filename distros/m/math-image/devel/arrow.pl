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
use Glib;
use Gtk2 '-init';

use Smart::Comments;

{
  Gtk2::Rc->parse_string (<<'HERE');
style "my_style" {
  GtkArrow::arrow-scaling = 1
  GtkButton::focus-padding = 0
  GtkButton::interior-focus = 0
  GtkButton::focus-line-width = 0
  GtkButton::image-spacing = 0
}
class "GtkArrow" style:highest "my_style"
class "GtkButton" style:application "my_style"
widget "*.myname" style:highest "my_style"
HERE

  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

  my $ebox = Gtk2::Frame->new;
  $ebox->modify_bg ('normal', Gtk2::Gdk::Color->parse('green'));

  my $button = Gtk2::Button->new; # ('button', 0, 100, 1);
  $button->modify_bg ('normal', Gtk2::Gdk::Color->parse('green'));
  $button->set (relief => 'none');
  # $button->style_set_property
  # $ebox->add ($button);
  $toplevel->add ($button);

  my $arrow = Gtk2::Arrow->new ('up', 'out');
  $arrow->set_name ('myname');
  $arrow->modify_bg ('normal', Gtk2::Gdk::Color->parse('green'));
  $arrow->set_size_request (50,50);
  # $ebox->add ($arrow);
  $button->add ($arrow);

  if ($arrow->can('list_style_properties')) {
    foreach my $paramspec ($button->list_style_properties) {
      my $pname = $paramspec->{'name'};
      my $value = $button->style_get($pname) // '[undef]';
      print "$pname $value\n";
    }
  }

  $toplevel->show_all;

  Glib::Timeout->add (2000, sub {
                        ### border: $ebox->get('border-width')
                        ### border: $button->get('border-width')
                        ### button: $button->allocation->values
                        ### arrow: $button->allocation->values
                        ### xpad: $arrow->get('xpad')
                        ### ypad: $arrow->get('ypad')
                        ### scaling: $arrow->style_get ('arrow-scaling')
                        return Glib::SOURCE_REMOVE;
                      });

  Gtk2->main;
  exit 0;
}

