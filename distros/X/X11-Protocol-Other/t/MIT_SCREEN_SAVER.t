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

my $test_count = (tests => 19)[1];
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
$X->QueryPointer($X->root);  # sync

{
  my ($major_opcode, $first_event, $first_error)
    = $X->QueryExtension('MIT-SCREEN-SAVER');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no MIT-SCREEN-SAVER on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("MIT-SCREEN-SAVER extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('MIT-SCREEN-SAVER')) {
  die "QueryExtension says MIT-SCREEN-SAVER avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

my $mit_obj = $X->{'ext'}->{'MIT_SCREEN_SAVER'}->[3];
ok (!!$mit_obj, 1, 'Mit object');

#------------------------------------------------------------------------------
# MitScreenSaverQueryVersion

{
  my ($major, $minor) = $X->MitScreenSaverQueryVersion (1,0);
  MyTestHelpers::diag ("MIT-SCREEN-SAVER extension version $major.$minor");
}


#------------------------------------------------------------------------------
# MitScreenSaverKind enum

{
  ok ($X->num('MitScreenSaverKind','Blanked'),  0);
  ok ($X->num('MitScreenSaverKind','Internal'), 1);
  ok ($X->num('MitScreenSaverKind','External'), 2);

  # ok ($X->interp('DbeSwapAction',0), 'Undefined');
  # ok ($X->interp('DbeSwapAction',1), 'Background');
  # ok ($X->interp('DbeSwapAction',2), 'Untouched');
  # ok ($X->interp('DbeSwapAction',3), 'Copied');
}

#------------------------------------------------------------------------------
# MitScreenSaverQueryInfo

{
  my @info = $X->MitScreenSaverQueryInfo ($X->root);
  ok (scalar(@info), 6);

  my ($state, $window, $til_or_since, $idle, $event_mask, $kind) = @info;
  ok ($window ne '0', 1, 'window should not be 0 ("None" instead)');
  ok ($event_mask >= 0, 1, 'event_mask');
  ok ($idle >= 0, 1, 'idle milliseconds');
}

#------------------------------------------------------------------------------
# MitScreenSaverSelectInput

{
  $X->MitScreenSaverSelectInput ($X->root, 0x03);
  $X->QueryPointer($X->root); # sync

  $X->MitScreenSaverSelectInput ($X->root, 0);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------

# could fail if another saver running
{
  my $root_width = $X->width_in_pixels;
  my $root_height = $X->height_in_pixels;

  my $skip;
  {
    my $orig_error_handler = $X->{'error_handler'};
    local $X->{'error_handler'} = sub {
      my ($X, $data) = @_;
      ### error handler
      ### $data

      my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;
      if ($X->interp('Error',$type) eq 'Access') {
        MyTestHelpers::diag ("ignore MitScreenSaverSetAttributes error \"Access\", another saver is running");
        $skip = 'due to Access error for another screen saver running';
      } else {
        goto $orig_error_handler;
      }
    };

    $X->MitScreenSaverSetAttributes ($X->root,
                                     'InputOutput',    # class
                                     0,                # depth, from parent
                                     'CopyFromParent', # visual
                                     0,0,              # x,y
                                     $root_width, $root_height,
                                     0,                # border
                                     background_pixel => $X->white_pixel,
                                    );
    $X->QueryPointer($X->root); # sync
  }
  ok (1, 1, 'MitScreenSaverSetAttributes');

  my $saw_on = 0;
  my $saw_off_again = 0;
  my %notify;
  $X->MitScreenSaverSelectInput ($X->root, 0x03);
  local $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h

    if ($h{'name'} eq 'MitScreenSaverNotify') {
      MyTestHelpers::diag ("MitScreenSaverNotify state=$h{'state'} kind=$h{'kind'} forced=$h{'forced'}");
      %notify = %h;

      if ($notify{'state'} eq 'On') {
        $saw_on = 1;
      }
      if ($saw_on && $notify{'state'} eq 'Off') {
        $saw_off_again = 1;
      }
    }
  };

  {
    $X->ForceScreenSaver ('Activate');
    $X->QueryPointer($X->root); # sync

    # maybe the user turns the saver off very quickly, or something
    if ($saw_off_again) {
      MyTestHelpers::diag ("skip tests due to saver turned off again");
      $skip = 'saver turned off again by something';
      $saw_off_again = 0;
    }
    skip ($skip,
          $notify{'state'}, 'On');
    skip ($skip,
          $notify{'time'} ne '0', 1);
    skip ($skip,
          $notify{'window'} > 0, 1);
    skip ($skip,
          $notify{'kind'}, 'External');
    skip ($skip,
          $notify{'forced'}, 1);
  }

  {
    my @info = $X->MitScreenSaverQueryInfo ($X->root);
    my ($state, $window, $til_or_since, $idle, $event_mask, $kind) = @info;

    # maybe the user turns the saver off very quickly, or something
    if ($saw_off_again) {
      MyTestHelpers::diag ("skip tests due to saver turned off again");
      $skip = 'saver turned off again by something';
      $saw_off_again = 0;
    }
    skip ($skip,
          $state, 'On');
    skip ($skip,
          $kind, 'External');
    skip ($skip,
          $event_mask, 3);
    skip ($skip,
          $window, $notify{'window'});
  }

  $X->ForceScreenSaver ('Reset');
  $X->QueryPointer($X->root); # sync

  $X->MitScreenSaverUnsetAttributes ($X->root);
  $X->QueryPointer($X->root); # sync

  ok (1, 1, 'MitScreenSaverUnsetAttributes() succeeded');
}

#------------------------------------------------------------------------------
# MitScreenSaverUnsetAttributes

{
  $X->MitScreenSaverUnsetAttributes ($X->root);
  $X->QueryPointer($X->root); # sync
}

# when not already set is not an error
{
  $X->MitScreenSaverUnsetAttributes ($X->root);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
exit 0;
