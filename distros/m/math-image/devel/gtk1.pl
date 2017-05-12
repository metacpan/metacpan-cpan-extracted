#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

use 5.004;
use strict;

use blib '/so/gtk1/Gtk-Perl-0.7009/GdkPixbuf/blib/';

# uncomment this to run the ### lines
use Devel::Comments;


{
  $ENV{DISPLAY} ||= ':0';
  require App::MathImage::Gtk1::Ex::Units;
  Gtk->init;
  my $label = Gtk::Label->new;
  print App::MathImage::Gtk1::Ex::Units::em($label),"\n";
  print App::MathImage::Gtk1::Ex::Units::char_width($label),"\n";
  print App::MathImage::Gtk1::Ex::Units::digit_width($label),"\n";

  print "ex ", App::MathImage::Gtk1::Ex::Units::ex($label),"\n";
  print "line_height ", App::MathImage::Gtk1::Ex::Units::line_height($label),"\n";

  exit 0;
}

{
  require App::MathImage::Gtk1::AboutDialog;
  Gtk->init;
  my $dialog = App::MathImage::Gtk1::AboutDialog->new;
  ### $dialog
  $dialog->show;
  Gtk->main;
  exit 0;
}
{
  Gtk->init;
  Gtk::Window->register_subtype('App::MathImage::Gtk1::Main');
  my $win = Gtk::Window->new;
  $win->show;
  Gtk->main;
  exit 0;
}
