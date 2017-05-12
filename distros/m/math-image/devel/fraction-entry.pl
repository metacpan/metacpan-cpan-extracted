#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Glib::Ex::ConnectProperties;
use App::MathImage::Gtk2::FractionEntry;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $fraction = App::MathImage::Gtk2::FractionEntry->new;
my ($l_vbox, $entry, $o_vbox) = $fraction->get_children;
#my $o_vbox = $aspect->get_child;
my ($button) = $o_vbox->get_children;
$fraction->signal_connect_after (activate => sub {
                               print "$progname: activate @_\n";
                               print "  ",$fraction->get('text'),"\n";

                               ### vbox ythickness: $o_vbox->get_style->xthickness

                             });
$vbox->add ($fraction);

$o_vbox->signal_connect_after (size_allocate => sub {
                                 print "$progname: vbox size-allocate\n";
                                 my $req = $o_vbox->size_request;
                                 ### vbox desire: $req->width, $req->height
                                 $req = $o_vbox->allocation;
                                 ### vbox size: $req->width, $req->height
                               });

{
  my $button = Gtk2::CheckButton->new_with_label ('Sensitive');
  Glib::Ex::ConnectProperties->new
      ([$fraction, 'sensitive'],
       [$button, 'active']);
  $vbox->pack_start ($button, 0, 0, 0);
}

$toplevel->show_all;

my $req = $fraction->allocation;
### fraction size: $req->width, $req->height

$req = $entry->allocation;
### $entry
### entry size: $req->width, $req->height

$req = $o_vbox->allocation;
### $o_vbox
### vbox size: $req->width, $req->height

$req = $button->allocation;
### button size: $req->width, $req->height

Gtk2->main;
exit 0;
