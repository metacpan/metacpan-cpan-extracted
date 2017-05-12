#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
use X11::Protocol;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = (tests => 26)[1];
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

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ('Cannot connect to X server -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Cannot connect to X server', 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

my ($major_opcode, $first_event, $first_error)
  = $X->QueryExtension('TOG-CUP');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no TOG-CUP on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("TOG-CUP extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('TOG-CUP')) {
  die "QueryExtension says TOG-CUP avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# CupQueryVersion

{
  my $client_major = 1;
  my $client_minor = 0;
  my @ret = $X->CupQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("server TOG-CUP version ", join('.',@ret));
  ok (scalar(@ret), 2);
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# CupGetReservedColormapEntries

{
  my $screen_num = 0;
  my @colours = $X->CupGetReservedColormapEntries ($screen_num);
  my $bad = 0;
  my $c;
  foreach $c (@colours) {
    if (scalar(@$c) != 5) {
      MyTestHelpers::diag ("oops, bad colour length: ", scalar(@$c));
      last if ++$bad > 10;
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# find a writable visual, preferably a colour one

my $visual;
my $visual_is_colour;
{
  my $v;
  foreach $v (sort {$a<=>$b} keys %{$X->{'visuals'}}) {
    my $info = $X->{'visuals'}->{$v};
    my $class = $X->interp('VisualClass',$info->{'class'});
    MyTestHelpers::diag ("visual $v $class depth=$info->{'depth'}");
    if ($class eq 'GrayScale'
        || $class eq 'PseudoColor'
        || $class eq 'DirectColor') {
      $visual = $v;
      $visual_is_colour = ($class eq 'GrayScale' ? 0 : 1);
      last if $visual_is_colour;
    }
  }
}
my $skip_no_writable_visual;
if (defined $visual) {
  MyTestHelpers::diag ("using visual=$visual, visual_is_colour=$visual_is_colour");
} else {
  $skip_no_writable_visual = 'due to no visual with a writable colormap';
  MyTestHelpers::diag ("no writable visual available");
}


#------------------------------------------------------------------------------
# CupStoreColors -- black and white

{
  my $colormap;
  if (defined $visual) {
    $colormap = $X->new_rsrc;
    $X->CreateColormap ($colormap, $visual, $X->root, 'None');
    $X->QueryPointer($X->{'root'}); # sync
  }

  {
    my @colours = ([0,0,0,0,0]);
    if (defined $colormap) {
      # store white
      @colours = $X->CupStoreColors ($colormap, [0, 65535,65535,65535]);
      $X->QueryPointer($X->{'root'}); # sync
      MyTestHelpers::diag ("white actual colour: ",join(', ',@{$colours[0]}));
    }
    skip ($skip_no_writable_visual, scalar(@colours), 1);
    skip ($skip_no_writable_visual, $colours[0]->[0], 0);
    skip ($skip_no_writable_visual, $colours[0]->[1] > 0, 1);
    skip ($skip_no_writable_visual, $colours[0]->[2] > 0, 1);
    skip ($skip_no_writable_visual, $colours[0]->[3] > 0, 1);
    skip ($skip_no_writable_visual, $colours[0]->[4] & 8, 8);  # succeed
  }
  {
    my @colours = ([0,0,0,0,0]);
    if (defined $colormap) {
      # store black
      @colours = $X->CupStoreColors ($colormap, [0, 0,0,0, 0]);
      $X->QueryPointer($X->{'root'}); # sync
      MyTestHelpers::diag ("black actual colour: ",join(', ',@{$colours[0]}));
    }
    skip ($skip_no_writable_visual, scalar(@colours), 1);
    skip ($skip_no_writable_visual, $colours[0]->[0] != 0, 1);
    skip ($skip_no_writable_visual, $colours[0]->[1], 0);
    skip ($skip_no_writable_visual, $colours[0]->[2], 0);
    skip ($skip_no_writable_visual, $colours[0]->[3], 0);
    skip ($skip_no_writable_visual, $colours[0]->[4] & 8, 8);  # at another pixel
  }

  if (defined $colormap) {
    $X->FreeColormap($colormap);
  }
}

#------------------------------------------------------------------------------
# CupStoreColors -- colour

my $skip_no_colour_visual;
if (! defined $visual) {
  $skip_no_colour_visual = $skip_no_writable_visual;
} elsif (! $visual_is_colour) {
  $skip_no_colour_visual = 'due to no writable colour visual';
  MyTestHelpers::diag ("skip, visual is not colour");
}

{
  my $colormap;
  if ($visual_is_colour) {
    $colormap = $X->new_rsrc;
    $X->CreateColormap ($colormap, $visual, $X->root, 'None');
    $X->QueryPointer($X->{'root'}); # sync
  }

  {
    my @colours = ([0,0,0,0,0]);
    if (defined $colormap) {
      # store red
      @colours = $X->CupStoreColors ($colormap, [0, 65535,0,0]);
      $X->QueryPointer($X->{'root'}); # sync
      MyTestHelpers::diag ("red actual colour: ",join(', ',@{$colours[0]}));
    }
    skip ($skip_no_colour_visual, scalar(@colours), 1);
    skip ($skip_no_colour_visual, $colours[0]->[0], 0);
    skip ($skip_no_colour_visual, $colours[0]->[1] > 0, 1);
    skip ($skip_no_colour_visual, $colours[0]->[2], 0);
    skip ($skip_no_colour_visual, $colours[0]->[3], 0);
    skip ($skip_no_colour_visual, $colours[0]->[4] & 8, 8);  # succeed
  }
  {
    my @colours = ([0,0,0,0,0]);
    if (defined $colormap) {
      # store blue
      @colours = $X->CupStoreColors ($colormap, [0, 0,0,65535, 0]);
      $X->QueryPointer($X->{'root'}); # sync
      MyTestHelpers::diag ("blue actual colour: ",join(', ',@{$colours[0]}));
    }
    skip ($skip_no_colour_visual, scalar(@colours), 1);
    skip ($skip_no_colour_visual, $colours[0]->[0] != 0, 1);
    skip ($skip_no_colour_visual, $colours[0]->[1], 0);
    skip ($skip_no_colour_visual, $colours[0]->[2], 0);
    skip ($skip_no_colour_visual, $colours[0]->[3] > 0, 1);
    skip ($skip_no_colour_visual, $colours[0]->[4] & 8, 8);  # at another pixel
  }
  if (defined $colormap) {
    $X->FreeColormap($colormap);
  }
}

#------------------------------------------------------------------------------

exit 0;
