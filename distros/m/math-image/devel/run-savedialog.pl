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
use App::MathImage::Gtk2::SaveDialog;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

my $dialog = App::MathImage::Gtk2::SaveDialog->new;
$dialog->signal_connect (destroy => sub { Gtk2->main_quit });
$dialog->set_current_name ('foo.PNG');


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

{
  my $button = Gtk2::Button->new_with_label ('Unset Type');
  $button->signal_connect (clicked => sub {
                             $dialog->{'combo'}->set (active_type => undef);
                           });
  $vbox->pack_start ($button, 0, 0, 0);
}


$dialog->show_all;
$toplevel->show_all;
Gtk2->main;

exit 0;
