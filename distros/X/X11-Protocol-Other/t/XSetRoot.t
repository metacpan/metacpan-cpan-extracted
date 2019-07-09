#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;


my $test_count = (tests => 7)[1];
plan tests => $test_count;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ("DISPLAY ", $display);

# Something fishy with xvfb test server seems to cause reconnects to fail.
# Keeping the initial connection seems better.  Dunno why.
#
my $keepalive_X;

# pass display arg so as not to get a "guess" warning
my $black_pixel;
{
  my $X;
  if (! eval { $X = X11::Protocol->new ($display); }) {
    MyTestHelpers::diag ('Cannot connect to X server -- ',$@);
    foreach (1 .. $test_count) {
      skip ('Cannot connect to X server', 1, 1);
    }
    exit 0;
  }
  $black_pixel = $X->black_pixel;
  MyTestHelpers::diag ("black_pixel = $black_pixel");
  $keepalive_X = $X;
}

require X11::Protocol::XSetRoot;

#------------------------------------------------------------------------------
# VERSION

my $want_version = 31;
ok ($X11::Protocol::XSetRoot::VERSION,
    $want_version,
    'VERSION variable');
ok (X11::Protocol::XSetRoot->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { X11::Protocol::XSetRoot->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { X11::Protocol::XSetRoot->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
### set_background() ...

# for use_esetroot need a new $X every time
#
foreach my $use_esetroot ([], [use_esetroot => 1]) {
  foreach my $options ([ display => $display, color => 'black' ],
                       [ display => $display, color => 'white' ],
                       [ display => $display, color => 'green' ],
                       [ display => $display, pixel => $black_pixel ],
                       [ pixmap => 0 ],
                       [ pixmap => "None" ],
                      ) {
    my @options = @$options;
    unless (@options && $options[0] eq 'display') {
      my $X = X11::Protocol->new ($display);
      push @options, X => $X;
    }
    ### options: "@options @$use_esetroot"
    X11::Protocol::XSetRoot->set_background
        (@options,
         @$use_esetroot);
  }

  {
    my $X = X11::Protocol->new ($display);
    my $pixmap = $X->new_rsrc;
    $X->CreatePixmap ($pixmap,
                      $X->{'root'},
                      $X->{'root_depth'},
                      1,1);  # width,height
    X11::Protocol::XSetRoot->set_background
        (X => $X,
         pixmap => $pixmap,
         @$use_esetroot);
  }
  {
    my $X = X11::Protocol->new ($display);
    my $pixmap = $X->new_rsrc;
    $X->CreatePixmap ($pixmap,
                      $X->{'root'},
                      $X->{'root_depth'},
                      1,1);  # width,height
    $X->QueryPointer($X->{'root'});  # sync
    X11::Protocol::XSetRoot->set_background
        (X => $X,
         pixmap => $pixmap,
         pixmap_allocated_colors => 1,
         @$use_esetroot);
    undef $X;
  }
}

# cleanup back to default
X11::Protocol::XSetRoot->set_background
  (display => $display, pixmap => "None");

#------------------------------------------------------------------------------
# _tog_cup_pixel_is_reserved()

{
  my $X = X11::Protocol->new ($display);

  my $screen_num = 0;
  ### $screen_num

  my $black_pixel = $X->{'screens'}->[$screen_num]->{'black_pixel'};
  my $white_pixel = $X->{'screens'}->[$screen_num]->{'white_pixel'};

  # results if TOG-CUP not initialized ... but currently always automatically
  # attempted
  #
  # {
  #   ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,$white_pixel),
  #       0);
  #   ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,$black_pixel),
  #       0);
  #   ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,-99),
  #       0);
  # }

  {
    my $got = X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,$white_pixel);

    my $have_tog_cup = ($X->init_extension('TOG-CUP') ? 1 : 0);
    MyTestHelpers::diag ("have TOG-CUP: $have_tog_cup");
    my $want_yes = ($have_tog_cup ? 1 : 0);

    ok ($got,
        $want_yes,
        'white_pixel in TOG-CUP reserved');
    ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,$black_pixel),
        $want_yes,
        'black_pixel in TOG-CUP reserved');
    ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,-99),
        0,
        'bogus pixel not in TOG-CUP reserved');
  }
}



#------------------------------------------------------------------------------
### exit ...
exit 0;
