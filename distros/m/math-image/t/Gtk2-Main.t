#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
# FIXME: some gtk asserts during destruction not yet worked out ...
# BEGIN { MyTestHelpers::nowarnings() }

use Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
MyTestHelpers::glib_gtk_versions();

plan tests => 24;

require App::MathImage::Gtk2::Main;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 110;
{
  is ($App::MathImage::Gtk2::Main::VERSION, $want_version,
      'VERSION variable');
  is (App::MathImage::Gtk2::Main->VERSION, $want_version,
      'VERSION class method');

  ok (eval { App::MathImage::Gtk2::Main->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::MathImage::Gtk2::Main->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $main = App::MathImage::Gtk2::Main->new;
  is ($main->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $main->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $main->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  $main->destroy;
}


#-----------------------------------------------------------------------------
# actions

my $have_cross = Module::Util::find_installed('Gtk2::Ex::CrossHair');
my $have_podviewer = Module::Util::find_installed('Gtk2::Ex::PodViewer');

{
  my $main = App::MathImage::Gtk2::Main->new;
  $main->show;

  my $actiongroup = $main->{'actiongroup'};
  foreach my $name ('SaveAs',
                    'About',
                    # 'Print', # interactive run ...
                    'Random','Random','Random','Random','Random','Random',
                    'Centre',
                    'ToolbarHorizontal','ToolbarVertical','ToolbarHide',
                    'Fullscreen',
                    'DrawProgressive',
                    ($have_cross ? 'Cross' : 'no-Cross'),
                    ($have_podviewer ? 'PodDialog' : 'no-PodDialog'),
                   ) {
    diag "action $name";
  SKIP: {
      if ($name =~ /^no-/) {
        skip "due to $name", 1;
      }
      my $action = $actiongroup->get_action ($name);
      ok ($action, "action $name");

      if ($name eq 'SaveAs') {
        # avoid spam from the file chooser
        local $SIG{'__WARN__'} = \&MyTestHelpers::warn_suppress_gtk_icon;
        $action->activate;
      } else {
        $action->activate;
      }
      foreach my $toplevel (Gtk2::Window->list_toplevels) {
        if (ref $toplevel =~ /^App::MathImage::/
            && $toplevel != $main) {
          diag "destroy $toplevel";
          $toplevel->destroy;
        }
      }
    }
  }
  diag "destroy main";
  $main->destroy;
  MyTestHelpers::main_iterations();
}

#-----------------------------------------------------------------------------
# Scalar::Util::weaken

{
  diag "weakening";
  my $main = App::MathImage::Gtk2::Main->new;
  diag "destroy main";
  $main->destroy;
  require Scalar::Util;
  Scalar::Util::weaken ($main);
  is ($main, undef, 'garbage collect when weakened');
}

exit 0;
