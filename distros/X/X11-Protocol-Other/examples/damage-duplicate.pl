#!/usr/bin/perl -w

# Copyright 2011, 2012, 2017 Kevin Ryde

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


# Usage: perl damage-duplicate.pl
#        perl damage-duplicate.pl --id 0x120000f
#
# This is an example of duplicating the contents of a window in real-time by
# listening for changes to it with the DAMAGE extension.
#
# A new $window toplevel displays the contents of a $source window.  The key
# feature of the damage extension is that it reports when $source changes.
# Without that, a duplicating program like this would have to re-copy every
# 1 second or something like that.
#
# The source window can be given as an XID with the "--id" command line
# option, otherwise an X11::Protocol::ChooseWindow is run so you can click
# on a window like xwininfo does.
#
# Details:
#
# In the event_handler() code care is taken not to do anything which reads a
# reply.  This is because reading the reply may also read and process other
# events, which would call event_handler() recursively and possibly
# endlessly.  Any event handler should bear that in mind.  In this program
# the danger would be that if the $source window is changing rapidly and so
# causing a new DamageNotify event to come very soon after each
# DamageSubtract().
#
# The $gc used for copying has "graphics_expose" off, which means any parts
# not available in the source window are cleared to the destination
# background colour.  This happens when the source is overlapped etc by
# other windows.
#
# In the core protocol there's no easy way to get content from $source when
# it's overlapped, since the server generally doesn't keep the contents or
# generate expose events for obscured parts of windows.
#
# If the "Composite" extension is available then it retains content of
# overlapped windows.  CompositeRedirectWindow() in the setups is all that's
# needed to have full $source contents available for the CopyArea()s.
#
# For simplicity the entire source area is copied whenever it changes.  In a
# more sophisticated program the "$parts_region" of changes from the damage
# object could be a clip mask for the CopyArea().  Changes outside the
# duplicated area would then still go back and forward as DamageNotify and
# CopyArea, but the server would see from the clip region no actual drawing
# required.
#
# If $window is bigger than the $source then the excess is cleared.  Some
# care is taken to clear only the excess area, not the whole of $window,
# since the latter way would make it flash to black and then to the copied
# $source.  On a fast screen you might not notice, but on a slow screen or
# if the server is bogged down then such flashing is very unattractive.
#
# Shortcomings:
#
# The created $window is always on the same screen as $source and uses the
# same depth, visual and colormap.  Doing so means a simple CopyArea
# suffices to copy the contents across.
#
# If source and destination were different depth, visual or colormap then
# pixel colour conversions would be required.  If the destination was on a
# different server or different screen then some data transfers with
# GetImage() and PutImage() would be needed as well as pixel conversions.
# (X11::Protocol::Ext::MIT_SHM might do that through shared memory if the
# program is on the same machine as the server.)
#
# Duplicating the root window is specifically disallowed here.  The problem
# is that a draw to $window is a change to the root contents, so generates
# another DamageNotify, which does another draw, in an infinite loop.  It
# might work if attention was paid to what parts of the root had changed.
# Changes to the part of the root which is unobscured parts of $window will
# be due to the duplicating drawing and so don't require any further
# drawing.
#

BEGIN { require 5 }
use strict;
use Getopt::Long;
use X11::AtomConstants;
use X11::CursorFont;
use X11::Protocol;
use X11::Protocol::WM;

# uncomment this to run the ### lines
#use Smart::Comments;

my $X = X11::Protocol->new (':0');

if (! $X->init_extension('DAMAGE')) {
  print "DAMAGE extension not available on the server\n";
  exit 1;
}

#------------------------------------------------------------------------------
# command line

my $source;       # source window to duplicate
my $verbose = 1;
GetOptions ('id=s'     => \$source,
            'verbose+' => \$verbose)
  or exit 1;

#------------------------------------------------------------------------------
# source window, from command line or chosen

my $popup_time;

if (defined $source) {
  # command line --id=XID
  $source = oct($source);  # oct() for hex 0xA0000F style as well as decimal
} else {
  require X11::Protocol::ChooseWindow;
  print "Click on a window to duplicate ...\n";
  $source = X11::Protocol::ChooseWindow->choose (X => $X);
  print "  got it\n";
}

if ($verbose) {
  printf "Source window %d (0x%X)\n", $source, $source;
}
if ($source == $X->root) {
  print "Cannot duplicate root window\n";
  exit 1;
}

#------------------------------------------------------------------------------

# use the Composite extension, if available, to keep the contents of $source
# if it's overlapped by other windows.
if ($X->init_extension('Composite')) {
  $X->CompositeRedirectWindow ($source, 'Automatic');
}

#------------------------------------------------------------------------------

my %source_geom = $X->GetGeometry($source);
my %source_attr = $X->GetWindowAttributes($source);

# create new output window to show a duplicate of $source
# same depth, visual, colormap
my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',    # class
                  $source_geom{'depth'},
                  $source_attr{'visual'},
                  0,0,              # x,y
                  100,100,          # w,h initial size
                  0,                # border
                  colormap         => $source_attr{'colormap'},
                  background_pixel => $X->black_pixel,
                  event_mask       => $X->pack_event_mask('Exposure'),
                 );
X11::Protocol::WM::set_wm_class ($X, $window,
                                 'damage-duplicate', 'DamageDuplicate');
X11::Protocol::WM::set_wm_name ($X, $window, 'Duplicate Window'); # title
X11::Protocol::WM::set_wm_icon_name ($X, $window, 'Duplicate');
X11::Protocol::WM::set_wm_client_machine_from_syshostname ($X, $window);
X11::Protocol::WM::set_net_wm_pid ($X, $window);
X11::Protocol::WM::set_net_wm_user_time($X, $window, $popup_time);
$X->MapWindow ($window);

# select ConfigureNotify from $source, to know when it resizes
$X->ChangeWindowAttributes
  ($source,
   event_mask => $X->pack_event_mask('StructureNotify'));

# the damage object to monitor $source
# creating this gives DamageNotify events
my $damage = $X->new_rsrc;
$X->DamageCreate ($damage, $source, 'NonEmpty');

my $gc = $X->new_rsrc;
$X->CreateGC ($gc, $window,
              subwindow_mode => 'IncludeInferiors',
              # no "graphics exposures", don't want GraphicsExpose events if
              # a part of the $X->CopyArea is obscured
              graphics_exposures => 0);

sub event_handler {
  my (%h) = @_;
  my $name = $h{'name'};
  ### event_handler()
  ### $name
  if ($name eq 'ConfigureNotify') {
    # $source has resized
    ### height: $h{'height'}
    my $width = $h{'width'};    # of $source
    my $height = $h{'height'};
    # clear any excess if $source has shrunk
    $X->ClearArea ($window, $width,0, 0,0);  # to left of $width
    $X->ClearArea ($window, 0,$height, 0,0); # below $height
    # copy any extra if $source has expanded
    $X->CopyArea ($source, $window, $gc,
                  0,0,                       # src x,y
                  $h{'width'},$h{'height'},  # src w,h
                  0,0);                      # dst x,y

  } elsif ($name eq 'DamageNotify') {
    # $source has been drawn into
    my $rect = $h{'geometry'};
    my ($root_x, $root_y, $width, $height) = @$rect;
    ### $rect
    $X->DamageSubtract ($damage, 'None', 'None');
    $X->CopyArea ($source, $window, $gc,
                  0,0,         # src x,y
                  $width,$height,
                  0,0);        # dst x,y

  } elsif ($name eq 'Expose') {
    # our $window revealed, draw it
    $X->CopyArea ($source, $window, $gc,
                  $h{'x'},$h{'y'},           # src x,y
                  $h{'width'},$h{'height'},  # src w,h
                  $h{'x'},$h{'y'});          # dst x,y
  }
}

$X->{'event_handler'} = \&event_handler;
for (;;) {
  $X->handle_input;
}
exit 0;
