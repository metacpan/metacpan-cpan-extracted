#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use App::MathImage::Gtk2::Ex::ToolItem::ComboText;

use Smart::Comments;

use FindBin;
my $progname = $FindBin::Script;

Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux',
                           # 100 .. 105,
                          );

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$vbox->show;
$toplevel->add ($vbox);

my $toolbar = Gtk2::Toolbar->new;
$toolbar->show;
$vbox->pack_start ($toolbar, 0,0,0);


{
  my $toolitem = Gtk2::ToolButton->new(undef,'ZZZZZZ');
  $toolitem->show;
  $toolbar->insert($toolitem, -1);
}

my $combobox = Gtk2::ComboBox->new_text;
$combobox->append_text ('One');
$combobox->append_text ('Two');
$combobox->append_text ('Three');
$combobox->set (tooltip_text => 'ComboBox tooltip',
                add_tearoffs => 1);
$combobox->show;
$combobox->signal_connect
  (notify => sub {
     my ($combobox, $pspec) = @_;
     print "$progname: combobox notify ",$pspec->get_name,"\n";
   });
$combobox->signal_connect
  (changed => sub {
     my ($combobox) = @_;
     my $iter = $combobox->get_active_iter;
     my $path = $iter ? $combobox->get_model->get_path($iter) : Gtk2::TreePath->new;
     print "$progname: combobox changed active: ",$path->to_string,"\n";
   });

my $toolitem = App::MathImage::Gtk2::Ex::ToolItem::ComboText->new
  (child => $combobox,
   overflow_mnemonic => '_Foo',
   visible => 1,
   tooltip_text => 'Tooltip on toolitem');
$toolitem->show;
$toolitem->signal_connect
  (notify => sub {
     my ($toolitem, $pspec) = @_;
     print "$progname: toolitem notify ",$pspec->get_name,"\n";
   });
$toolbar->insert($toolitem,-1);

my $menuitem;
{
  my $button = Gtk2::Button->new_with_label ('menuitem');
  $button->signal_connect
    (clicked => sub {
       $menuitem = $toolitem->get_proxy_menu_item
         ('App::MathImage::Gtk2::Ex::ToolItem::ComboText');
       ### $menuitem
       if ($menuitem) {
         $button->signal_connect (destroy => sub {
                                    print "$progname: menuitem destroy\n";
                                  });
       }
       require Scalar::Util;
       Scalar::Util::weaken ($menuitem);
     });
  $button->show_all;
  $vbox->pack_start ($button, 0, 0, 0);
}

{
  my $button = Gtk2::Button->new_with_label ('destroy toolitem');
  $button->signal_connect
    (clicked => sub {
       $menuitem = $toolitem->get_proxy_menu_item
         ('App::MathImage::Gtk2::Ex::ToolItem::ComboText');
       require Scalar::Util;
       Scalar::Util::weaken ($menuitem);
       Scalar::Util::weaken ($toolitem);
       $toolitem->destroy;
       ### $toolitem
       ### $menuitem
     });
  $button->show_all;
  $vbox->pack_start ($button, 0, 0, 0);
}

{
  my $button = Gtk2::CheckButton->new_with_label ('Toolitem Sensitive');
  require Glib::Ex::ConnectProperties;
  Glib::Ex::ConnectProperties->new
      ([$toolitem, 'sensitive'],
       [$button, 'active']);
  $button->show;
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::CheckButton->new_with_label ('Child Sensitive');
  Glib::Ex::ConnectProperties->new
      ([$combobox, 'sensitive'],
       [$button, 'active']);
  $button->show;
  $vbox->pack_start ($button, 0, 0, 0);
}

$toplevel->show;
Gtk2->main;
exit 0;

