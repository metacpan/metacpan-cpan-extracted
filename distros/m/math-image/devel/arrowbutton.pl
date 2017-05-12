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
use App::MathImage::Gtk2::Ex::ArrowButton;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $layout = Gtk2::Layout->new;
$vbox->pack_start ($layout, 0, 0, 0);

# my $ab = Gtk2::Arrow->Glib::Object::new;
my $ab = App::MathImage::Gtk2::Ex::ArrowButton->new (arrow_type => 'up');
$ab->signal_connect_after (clicked => sub {
                             print "$progname: clicked @_\n";
                           });
$vbox->add ($ab);
# $layout->put ($ab, 0,0);
$toplevel->set_default_size (200, 200);

if (0) {
  my $button = Gtk2::CheckButton->new_with_label ('Sensitive');
  Glib::Ex::ConnectProperties->new
      ([$ab, 'sensitive'],
       [$button, 'active']);
  $vbox->pack_start ($button, 0, 0, 0);
}

$toplevel->show_all;

my $req = $ab->size_request;
### size_request: $req->width, $req->height

my $arrow = $ab->get_child;
### arrow
$req = $arrow->size_request;
### size_request: $req->width, $req->height
### xpad: $arrow->get_property('xpad')
### ypad: $arrow->get_property('ypad')

### normal: $ab->style->fg('normal')->to_string
### prelight: $ab->style->fg('prelight')->to_string
### active: $ab->style->fg('active')->to_string
### selected: $ab->style->fg('selected')->to_string
### insensitive: $ab->style->fg('insensitive')->to_string

### normal: $ab->style->bg('normal')->to_string
### prelight: $ab->style->bg('prelight')->to_string
### active: $ab->style->bg('active')->to_string
### selected: $ab->style->bg('selected')->to_string
### insensitive: $ab->style->bg('insensitive')->to_string

### focus-line-width: $ab->style_get_property('focus-line-width')
### focus-padding: $ab->style_get_property('focus-padding')
### inner-border: $ab->style_get_property('inner-border')
### default-border: $ab->style_get_property('default-border')
### image-spacing: $ab->style_get_property('image-spacing')

### focus-line-width: $ab->get_child->style_get_property('focus-line-width')
### focus-padding: $ab->get_child->style_get_property('focus-padding')
### arrow-scaling: $ab->get_child->style_get_property('arrow-scaling')

Gtk2->main;
exit 0;
