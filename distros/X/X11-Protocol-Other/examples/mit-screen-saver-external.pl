#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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


# Usage: perl mit-screen-saver-external.pl
#
# This is an example of an external screen saver using the MIT-SCREEN-SAVER
# extension (X11::Protocol::Ext::MIT_SCREEN_SAVER).
#
# MitScreenSaverSetAttributes() sets up the program to be an external saver
# and defines the saver window attributes for when the saver turns on.
# MitScreenSaverSelectInput() sets up to listen for when the saver does in
# fact turn on.  Then redraw() is a moving blob in the saver window while
# active.
#
#
# Drawing:
#
# redraw() is done on a timer at $frame_rate many times per second.  An
# IO::Select is used to wait for either an event from the server or the
# desired time.  When the saver is off there's no timeout, just wait for
# events.
#
# The timeout ought to be the time from now until the next draw is due, and
# in theory the time ought to be only until the blob moves by a whole pixel.
# But it's much easier to consider a draw every select().  This is normally
# fine since there shouldn't be many events from the server and so most
# selects end for time not for input.
#
# The main loop also listens to STDIN for "f" from the user to force the
# screen saver on, so you don't have to wait to see the demo.  In a real
# program you'd probably ignore STDIN since the program would usually run in
# the background with stdin either closed at startup or ignored.
#
# An error handler guards against the saver turning off during drawing.
# When the saver turns off the saver window cannot be used and drawing to it
# results in Drawable or Window errors.
#
# An error handler is necessary.  Errors from drawing can't be avoided by
# checking the saver state.  Even if the saver is On when the drawing
# requests are sent out it might be off by the time those requests reach the
# server.
#
# The drawing isn't very sophisticated, but does try to reduce flashing by
# clearing only the newly revealed background part of the window when moving
# the blob.  A fancier program could draw a new frame to a pixmap and then
# copy that to the screen, or similar with the DOUBLE-BUFFER extension if
# available (X11::Protocol::Ext::DOUBLE_BUFFER).
#
# Incidentally the saver window doesn't have to be the full screen.  It can
# be something in the middle of the screen, leaving some normal screen
# content around the edges (which will update as normal if any clients are
# drawing, such as a clock).
#
#
# Another Screen Saver Running:
#
# The error handler notices an Access error from
# MitScreenSaverSetAttributes() which occurs if there's another external
# saver program running already.  MitScreenSaverSetAttributes() doesn't have
# a reply when successful, so only the error packet says it didn't work.
# A round-trip QueryPointer ensures any error is detected before going into
# the main loop.
#
# Xlib XScreenSaverSaverRegister() has a scheme where a running saver
# program identifies itself by an XID stored in an "_MIT_SCREEN_SAVER_ID"
# property on the root window.  That allows an existing saver to be forcibly
# killed ($X->KillClient()) if desired, though whether that's a good idea
# when starting a new saver is another matter.  There's nothing in
# X11::Protocol::Ext::MIT_SCREEN_SAVER for that as yet.  Some care might be
# needed when owning that property not to leave behind a bogus XID if killed
# (because that XID could be assigned to another client).  Perhaps
# SetCloseDownMode() to preserve an identifying pixmap.
#
#
# Other Ways to Do It:
#
# For reference, the xscreensaver program has other ways to do a saver, as
# described in the comments at the start of its xscreensaver.c.  In addition
# to MIT-SCREEN-SAVER it can detect idleness with the old (and perhaps no
# longer available) XIdle extension, or with the SCREEN_SAVER on SGI Irix,
# and can even try some slightly nasty keypress events and polling the mouse
# pointer position.  And then it normally prefers to blank with an
# override-redirect window covering the screen.
#
# Apparently xscreensaver struck server bugs in the MIT-SCREEN-SAVER
# extension and for that reason recommends XIdle or SGI SCREEN_SAVER in its
# config.h.in.  Recent X.org servers don't seem to crash, and the note in
# config.h.in about trouble "fading" with MIT-SCREEN-SAVER might be due to
# setting a background_pixel colour in the way done in the code here.  If
# you omit that then like other windows the saver window leaves existing
# screen content unchanged when it's mapped.  (And from there could be
# manipulated with colormap trickery, or perhaps RENDER extension merging,
# or even some GetImage/PutImage.)
#

use strict;
use IO::Select;
use X11::Protocol;
use List::Util 'min';
use Time::HiRes 'usleep';
use POSIX 'fmod';


my $frame_rate = 20;
my $seconds_per_trip = 60;


my $X = X11::Protocol->new;
if (! $X->init_extension('MIT-SCREEN-SAVER')) {
  print STDERR "MIT-SCREEN-SAVER extension not available\n";
  exit 1;
}

my $orig_error_handler = $X->{'error_handler'};
local $X->{'error_handler'} = sub {
  my ($X, $data) = @_;
  my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;

  $type = $X->interp('Error',$type);
  $major_op = $X->interp('Request',$major_op);

  if ($type eq 'Access') {
    # could check $major_op is the saver extension opcode and $minor_op is
    # MitScreenSaverSetAttributes
    #
    print STDERR "Another screen saver is running\n";
    exit 1;

  } elsif (($type eq 'Window' || $type eq 'Drawable')
           && ($major_op eq 'ClearArea' || $major_op eq 'PolyFillRectangle')) {
    # screen saver turned off during drawing, ignore errors from the drawing
    # requests

  } else {
    goto $orig_error_handler;
  }
};

# listen for MitScreenSaverNotify
$X->MitScreenSaverSelectInput ($X->root, 0x01);

# screen saver window same depth as root
#
$X->MitScreenSaverSetAttributes
  ($X->root,
   'InputOutput',    # class
   0,                # depth, from parent
   'CopyFromParent', # visual
   0,0,              # x,y
   $X->width_in_pixels,
   $X->height_in_pixels,
   0,                # border
   background_pixel => $X->black_pixel,
  );

# round-trip query so as to get any Access error from
# MitScreenSaverSetAttributes() before printing the startup message below
#
$X->QueryPointer ($X->root);


my $gc = $X->new_rsrc;
$X->CreateGC ($gc, $X->root, foreground => $X->white_pixel);


my %saver_notify = (state => 'Off');

sub saver_is_active {
  return $saver_notify{'state'} eq 'On'
    && $saver_notify{'kind'} eq 'External';
}

$X->{'event_handler'} = sub {
  my (%h) = @_;
  if ($h{'name'} eq 'MitScreenSaverNotify') {
    %saver_notify = %h;
  }
};


# width and height of a single pixel
my $pixel_width_mm  = $X->width_in_millimeters / $X->width_in_pixels;
my $pixel_height_mm = $X->height_in_millimeters / $X->height_in_pixels;

my $blob_width = int ($X->width_in_pixels / 20);
my $blob_height = int ($blob_width * ($pixel_height_mm / $pixel_width_mm));

my $blob_x_limit = $X->width_in_pixels - $blob_width;

# middle of the screen vertically
my $blob_y = int (($X->height_in_pixels - $blob_height) / 2);

# Return $x of current desired blob position.  Time $seconds_per_trip
# corresponds to across and back, which is 2*$blob_x_limit pixels.
sub blob_x {
  my $t = Time::HiRes::time();
  my $x = int (2 * $blob_x_limit * fmod($t / $seconds_per_trip, 1));
  if ($x >= $blob_x_limit) {
    $x = 2*$blob_x_limit-1 - $x;
  }
  return $x;
}

my $last_blob_x = 0; # last drawn position

sub redraw {
  return unless saver_is_active();

  my $window = $saver_notify{'window'};
  my $blob_x = blob_x();

  my ($clear_x, $clear_width);
  if ($blob_x > $last_blob_x) {
    $clear_x = $last_blob_x;
    $clear_width = min ($blob_width, $blob_x - $last_blob_x);
  } else {
    $clear_width = min ($blob_width, $last_blob_x - $blob_x);
    $clear_x = $last_blob_x + $blob_width - $clear_width;
  }
  if ($clear_width) {
    $X->ClearArea ($window, $clear_x,$blob_y, $clear_width,$blob_height);
  }

  $X->PolyFillRectangle ($window, $gc,
                         [$blob_x, $blob_y, $blob_width-1, $blob_height-1]);

  $last_blob_x = $blob_x;
}

sub handle_stdin {
  my $line = <STDIN>;
  if (! defined $line || $line =~ /^q(uit)?/i) {
    exit 0;
  }
  if ($line =~ /^f(orce)?/i) {
    print "Force screen saver on ...\n";
    # Sleep to wait for the key release from the user pressing Return.
    # Could a fancier program check for all keys released ?
    sleep 1;
    $X->ForceScreenSaver ('Activate');
  }
}

my $X_fh = $X->{'connection'}->fh;
my $select = IO::Select->new ($X_fh, \*STDIN);

print "Waiting for idle, type \"f Return\" to force it.\n";
print "Type \"q Return\" to exit.\n";

for (;;) {
  $X->flush;
  my $timeout = (saver_is_active() ? 1/$frame_rate : 0);
  foreach my $readable ($select->can_read($timeout)) {
    if ($readable == $X_fh) {
      $X->handle_input;

    } elsif ($readable == \*STDIN) {
      handle_stdin();
    }
  }
  redraw();
}

exit 0;
