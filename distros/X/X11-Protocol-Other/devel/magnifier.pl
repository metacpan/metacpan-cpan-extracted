#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

use strict;
use X11::Protocol;

use lib 'devel', '.';

# uncomment this to run the ### lines
use Smart::Comments;

my $X = X11::Protocol->new (':0');
$X->{'event_handler'} = \&event_handler;

$X->init_extension('XFIXES') or die $@;
$X->init_extension('DAMAGE') or die $@;

$|=1;
my $root_x = 0;
my $root_y = 0;
my $width = 100;
my $height = 100;

my $origin = $X->root;
# my $origin = $X->new_rsrc;
# $X->CreateWindow ($origin,
#                   $X->root,         # parent
#                   'InputOutput',
#                   0,                # depth, from parent
#                   'CopyFromParent', # visual
#                   0,0,              # x,y
#                   20,20,
#                   0,                # border
#                  );
# $X->MapWindow ($origin);

my $origin_x = 1000;
my $origin_y = 0;
my $origin_region = $X->new_rsrc;
$X->XFixesCreateRegion ($origin_region, [$origin_x,$origin_y,10,10]);


my $parts = $X->new_rsrc;
$X->XFixesCreateRegion ($parts);

my $damage = $X->new_rsrc;
$X->DamageCreate ($damage, $origin, 'NonEmpty');
$X->QueryPointer ($X->{'root'});

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  $width,$height,
                  0,                # border
                  background_pixel => $X->black_pixel,
                  event_mask => $X->pack_event_mask('Exposure','KeyPress'),
                 );
$X->MapWindow ($window);

my $gc;
my $want_freshen;

sub event_handler {
  my (%h) = @_;
  ### event_handler: \%h
  if ($h{'name'} eq 'ConfigureNotify') {
    $width = $h{'width'};
    $width = $h{'height'};
    $want_freshen = 1;
  } elsif ($h{'name'} eq 'DamageNotify') {
    $want_freshen = 1;
  } elsif ($h{'name'} eq 'Expose') {
    expose();
  }
};

sub freshen {
  ### freshen(): $damage, $parts
  $X->DamageSubtract ($damage, 'None', $parts);
  dump_region ($X,$parts,'damaged');
  return if ! $window;

  $X->XFixesIntersectRegion ($parts, $origin_region, $parts);
  dump_region ($X,$parts,'intersected with origin');

  my $window_region = $X->new_rsrc;
  $X->XFixesCreateRegionFromWindow ($window_region, $window, 'Bounding');
  dump_region ($X,$window_region,'own window');

  my ($same_screen, $child, $x, $y)
    = $X->TranslateCoordinates ($window, $X->root, 0,0);
  ### $x
  ### $y
  $X->XFixesTranslateRegion ($window_region, $x, $y);
  dump_region ($X,$window_region,'own window translated');
  $X->XFixesSubtractRegion ($parts, $window_region, $parts);
  $X->XFixesDestroyRegion ($window_region);

  dump_region ($X,$parts,'subtracted own window');

  #    $X->XFixesSetGCClipRegion ($gc, $parts, 0,0);

  my ($bounding, @rects) = $X->XFixesFetchRegion ($parts);
  if ($bounding->[2] && $bounding->[3]) {
    expose();
  } else {
    ### no draw...
  }
}

sub expose {
  ### expose...
  if (! $gc) {
    ### make gc
    $gc = $X->new_rsrc;
    $X->CreateGC ($gc, $window, subwindow_mode => 'IncludeInferiors');
  }
  # $X->SetGCClipRegion ($gc, $parts, 0,0);
  $X->CopyArea ($origin, $window, $gc,
                $origin_x,$origin_y,
                $width,$height,
                0,0); # dst x,y
}

sub dump_region {
  my ($X, $region, $name) = @_;
  my @rects = $X->XFixesFetchRegion ($region);
  if (! defined $name) { $name = ''; }
  printf "region %X  $name\n", $region;
  if (@rects) {
    foreach my $rect (@rects) {
      print "  ",join(',',@$rect),"\n";
    }
  } else {
    print "  empty";
  }
}

sub fh_readable {
  my ($fh) = @_;
  require IO::Select;
  my $s = IO::Select->new;
  $s->add($fh);
  my @ready = $s->can_read(1);
  return scalar(@ready);
}

for (;;) {
  if (fh_readable ($X->{'connection'}->fh)) {
    ### handle_input
    $X->handle_input;
  }
  if ($want_freshen) {
    $want_freshen = 0;
    freshen();
  }
  # else {
  #    $X->handle_input;
  #  }
}

### exit
exit 0;
