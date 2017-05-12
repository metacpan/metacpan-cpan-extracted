#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Wx-Perl-PodBrowser.
#
# Wx-Perl-PodBrowser is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Wx-Perl-PodBrowser is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Wx-Perl-PodBrowser.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use Wx;
use Wx::RichText;

# uncomment this to run the ### lines
use Smart::Comments;

my $str;

{
  # EVT_MENU() not released on ->Delete()

  my $app = Wx::SimpleApp->new;
  require Wx::Perl::PodBrowser;
  my $browser = Wx::Perl::PodBrowser->new ();
  for (;;) {
    $browser->{'podtext'}->{'heading_list'} = [rand(),rand()];
    $browser->_update_history_menuitems;
    $browser->{'podtext'}->{'heading_list'} = [];
    $browser->_update_history_menuitems;
  }
  exit 0;
}

{
  # EVT_MENU() not released on ->Delete()

  my $app = Wx::SimpleApp->new;
  my $frame = Wx::Frame->new(undef, Wx::wxID_ANY(), 'Pod');

  my $menu = Wx::Menu->new ('Foo');
  for (;;) {
    my $item = $menu->Append (Wx::wxID_ANY(), 'label', 'help');
    Wx::Event::EVT_MENU ($frame, $item, sub{ print "hi\n"; });
    $menu->Delete($item);
    #    $menu->Remove($item);
  }
  exit 0;
}
