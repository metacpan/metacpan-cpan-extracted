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

my $test_count = (tests => 61)[1];
plan tests => $test_count;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);
MyTestHelpers::diag ("DISPLAY is ",
                     defined $ENV{'DISPLAY'} ? $ENV{'DISPLAY'} : 'undef');

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

{
  my ($major_opcode, $first_event, $first_error)
    = $X->QueryExtension('XFIXES');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no XFIXES on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("XFIXES extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('XFIXES')) {
  die "QueryExtension says XFIXES avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync


my $other_X = X11::Protocol->new ($display);

my $other_window = $other_X->new_rsrc;
$other_X->CreateWindow ($other_window,
                        $X->root,         # parent
                        'InputOutput',
                        0,                # depth, from parent
                        'CopyFromParent', # visual
                        0,0,              # x,y
                        100,100,          # width,height
                        0,                # border
                        background_pixel => $X->white_pixel,
                       );
$other_X->QueryPointer($other_X->root); # sync



#------------------------------------------------------------------------------
# XFixesWindowRegionKind enum

{
  ok ($X->num('XFixesWindowRegionKind','Bounding'), 0);
  ok ($X->num('XFixesWindowRegionKind','Clip'),     1);

  ok ($X->num('XFixesWindowRegionKind',0), 0);
  ok ($X->num('XFixesWindowRegionKind',1), 1);

  ok ($X->interp('XFixesWindowRegionKind',0), 'Bounding');
  ok ($X->interp('XFixesWindowRegionKind',1), 'Clip');
}

#------------------------------------------------------------------------------
# XFixesSaveSetMode enum

{
  ok ($X->num('XFixesSaveSetMode','Insert'), 0);
  ok ($X->num('XFixesSaveSetMode','Delete'), 1);

  ok ($X->num('XFixesSaveSetMode',0), 0);
  ok ($X->num('XFixesSaveSetMode',1), 1);

  ok ($X->interp('XFixesSaveSetMode',0), 'Insert');
  ok ($X->interp('XFixesSaveSetMode',1), 'Delete');
}

#------------------------------------------------------------------------------
# XFixesSaveSetTarget enum

{
  ok ($X->num('XFixesSaveSetTarget','Nearest'), 0);
  ok ($X->num('XFixesSaveSetTarget','Root'), 1);

  ok ($X->num('XFixesSaveSetTarget',0), 0);
  ok ($X->num('XFixesSaveSetTarget',1), 1);

  ok ($X->interp('XFixesSaveSetTarget',0), 'Nearest');
  ok ($X->interp('XFixesSaveSetTarget',1), 'Root');
}

#------------------------------------------------------------------------------
# XFixesSaveSetMap enum

{
  ok ($X->num('XFixesSaveSetMap','Map'), 0);
  ok ($X->num('XFixesSaveSetMap','Unmap'), 1);

  ok ($X->num('XFixesSaveSetMap',0), 0);
  ok ($X->num('XFixesSaveSetMap',1), 1);

  ok ($X->interp('XFixesSaveSetMap',0), 'Map');
  ok ($X->interp('XFixesSaveSetMap',1), 'Unmap');
}

#------------------------------------------------------------------------------
# _num_xinputdevice()

{
  ok (X11::Protocol::Ext::XFIXES::_num_xinputdevice('AllDevices'), 0);
  ok (X11::Protocol::Ext::XFIXES::_num_xinputdevice('AllMasterDevices'), 1);
}


#------------------------------------------------------------------------------
# XFixesCursorNotify event

{
  my $aref = $X->{'ext'}->{'XFIXES'};
  my ($request_num, $event_num, $error_num, $obj) = @$aref;

  my $more;
  foreach $more (0, 1) {
    my $time;
    foreach $time ('CurrentTime', 103) {
      my %input = (# can't use "name" on an extension event, at least in 0.56
                   # name      => "XFixesCursorNotify",
                   synthetic => 1,
                   code      => $event_num+1,
                   sequence_number => 100,

                   subtype       => 'DisplayCursor',
                   window        => 102,
                   cursor_serial => 103,
                   time          => $time,
                   cursor_name   => 104);

      my $data = $X->pack_event(%input);
      ok (length($data), 32);

      my %output = $X->unpack_event($data);
      ### %output

      ok ($output{'code'},          $input{'code'});
      ok ($output{'name'},          'XFixesCursorNotify');
      ok ($output{'synthetic'},     $input{'synthetic'});
      ok ($output{'window'},        $input{'window'});
      ok ($output{'cursor_serial'}, $input{'cursor_serial'});
      ok ($output{'time'},          $input{'time'});
      ok ($output{'cursor_name'},   $input{'cursor_name'});
    }
  }
}


#------------------------------------------------------------------------------
# XFixesQueryVersion

{
  my $client_major = 1;
  my $client_minor = 0;
  my @ret = $X->XFixesQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("XFixesQueryVersion ask for $client_major.$client_minor got server version ", join('.',@ret));
  ok (scalar(@ret), 2);
  ok ($ret[0] <= $client_major, 1);
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XFixesChangeSaveSet

{
  $X->XFixesChangeSaveSet ($other_window, 'Insert', 'Root', 'Unmap');
  $X->QueryPointer($X->root); # sync
  $X->XFixesChangeSaveSet ($other_window, 'Delete', 'Nearest', 'Map');
  $X->QueryPointer($X->root); # sync
}


#------------------------------------------------------------------------------
# XFixesSelectSelectionInput

{
  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    100,100,          # width,height
                    0,                # border
                    background_pixel => $X->white_pixel,
                   );
  $X->QueryPointer($X->root); # sync

  $X->XFixesSelectSelectionInput ($window, $X->atom('PRIMARY'), 0x07);
  $X->QueryPointer($X->root); # sync
  $X->XFixesSelectSelectionInput ($window, $X->atom('PRIMARY'), 0);
  $X->QueryPointer($X->root); # sync

  $X->DestroyWindow ($window);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XFixesSelectCursorInput

{
  $X->XFixesSelectCursorInput ($X->root, 1);
  $X->QueryPointer($X->root); # sync
  $X->XFixesSelectCursorInput ($X->root, 0);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XFixesGetCursorImage

{
  # Set a cursor before attempting to read back the image.  With xvfb of
  # x.org 1.11.4 at startup an attempt to XFixesGetCursorImage() or
  # XFixesGetCursorImageAndName() before a cursor has been set results in a
  # BadCursor error.  Sounds like a server bug or misfeature, but force it
  # as a workaround.

  my $cursor_font = $X->new_rsrc;
  $X->OpenFont ($cursor_font, "cursor");
  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,  # cursor font
                         $cursor_font,  # mask font
                         0,  # X_cursor glyph
                         1,  # X_cursor mask
                         0,0,0,
                         0xFFFF, 0xFFFF, 0xFFFF);
  $X->CloseFont ($cursor_font);
  $X->QueryPointer($X->root); # sync

  my $screen_info;
  foreach $screen_info (@{$X->{'screens'}}) {
    $X->ChangeWindowAttributes ($screen_info->{'root'},
                                cursor => $cursor);
  }
  $X->FreeCursor ($cursor);
  $X->QueryPointer($X->root); # sync
}

{
  my ($root_x,$root_y, $width,$height, $xhot,$yhot, $serial, $pixels)
    = $X->XFixesGetCursorImage ();
  $X->QueryPointer($X->root); # sync

  ok (length($pixels), 4*$width*$height);
}


#------------------------------------------------------------------------------
exit 0;
