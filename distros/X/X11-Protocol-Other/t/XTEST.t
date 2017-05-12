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

my $test_count = (tests => 16)[1];
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
  = $X->QueryExtension('XTEST');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no XTEST on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("XTEST extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('XTEST')) {
  die "QueryExtension says XTEST avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XTestGetVersion()

{
  my $client_major = 1;
  my $client_minor = 1;
  my @ret = $X->XTestGetVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("server XTEST version ", join('.',@ret));
  ok (scalar(@ret), 2);
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XTestCompareCursor()

{
  my $cursor_glyph = 4;

  my $cursor_font = $X->new_rsrc;
  $X->OpenFont ($cursor_font, "cursor");

  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,  # font
                         $cursor_font,  # mask font
                         $cursor_glyph,   # glyph number
                         $cursor_glyph+1, # and its mask
                         0,0,0,                    # foreground, black
                         0xFFFF, 0xFFFF, 0xFFFF);  # background, white

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->{'root'},     # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    1,1,              # width,height
                    0,                # border
                    cursor => $cursor);

  ok ($X->XTestCompareCursor ($window, $cursor),
      1);
  ok ($X->XTestCompareCursor ($window, "None"),
      0);
  ok ($X->XTestCompareCursor ($window, 0),
      0);
  $X->XTestCompareCursor ($window, "CurrentCursor");
  $X->XTestCompareCursor ($window, 1);

  $X->ChangeWindowAttributes
    ($window,
     cursor => 'None');

  ok ($X->XTestCompareCursor ($window, $cursor),
      0);
  ok ($X->XTestCompareCursor ($window, "None"),
      1);
  ok ($X->XTestCompareCursor ($window, 0),
      1);


  $X->CloseFont ($cursor_font);
  $X->DestroyWindow ($window);
  $X->FreeCursor ($cursor);
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# _fake_input_pack()

{
  my $packet = X11::Protocol::Ext::XTEST::_fake_input_pack
    ($X,
     name   => 'MotionNotify',
     root_x => 200,
     root_y => 500);
  ok (length($packet), 32);
}
{
  my $packet = X11::Protocol::Ext::XTEST::_fake_input_pack
    ($X,
     name   => 'MotionNotify',
     root   => 'None',
     root_x => 200,
     root_y => 500);
  ok (length($packet), 32);
}
{
  my $packet = X11::Protocol::Ext::XTEST::_fake_input_pack
    ($X,
     name   => 'ButtonPress',
     detail => 1,
     time   => 'CurrentTime');
  ok (length($packet), 32);
}
{
  my $packet = X11::Protocol::Ext::XTEST::_fake_input_pack
    ($X,
     name   => 'ButtonRelease',
     detail => 3,
     time   => 0);
  ok (length($packet), 32);
}

#------------------------------------------------------------------------------
# XTestFakeInput() -- mouse motion
{
  my %old = $X->QueryPointer($X->root);
  my $root = $old{'root'};
  $X->XTestFakeInput (name   => 'MotionNotify',
                      detail => 1,  # relative
                      root   => $root,
                      root_x => 200,
                      root_y => 500,
                     );
  # $X->flush;
  # sleep 1;

  # restore
  $X->XTestFakeInput ([ name   => 'MotionNotify',
                        detail => 0,   # absolute
                        root   => $root,
                        root_x => $old{'root_x'},
                        root_y => $old{'root_y'},
                      ]);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XTestFakeInput() -- key press/release
{
  my $first_keycode = $X->min_keycode;
  my $count_keycodes = $X->max_keycode - $first_keycode + 1;
  ### $first_keycode
  ### $count_keycodes
  my @keysyms = $X->GetKeyboardMapping ($first_keycode, $count_keycodes);
  ### keysyms length: scalar(@keysyms)

  # $keysym is an integer.
  # Return keycode (an integer), or undef if $keysym not on the keyboard.
  sub keysym_to_keycode {
    my ($keysym) = @_;
    my $i;
    foreach $i (0 .. $#keysyms) {
      my $aref = $keysyms[$i];
      my $j;
      foreach $j (0 .. $#$aref) {
        if ($aref->[$j] == $keysym) {
          return $i + $first_keycode;
        }
      }
    }
    return undef;
  }

  my $keycode = keysym_to_keycode(0xFFE1); # "Shift_L"
  # $keycode = keysym_to_keycode(0x05A); # "Z"
  # MyTestHelpers::diag ("keycode is ", $keycode);
  if (defined $keycode) {
    $X->XTestFakeInput (name   => 'KeyPress',
                        detail => $keycode,
                       );
    # $X->flush;
    # sleep 1;
    $X->XTestFakeInput (name   => 'KeyRelease',
                        detail => $keycode,
                       );
    $X->QueryPointer($X->root); # sync
  }
}

#------------------------------------------------------------------------------
# XTestGrabControl()

{
  my $X2 = X11::Protocol->new ($display);
  my $impervious;
  foreach $impervious (undef, 1, 0, 1, 0) {
    ### $impervious
    if (defined $impervious) {
      $X->XTestGrabControl ($impervious);
    }
    my $want_impervious = ($impervious ? 1 : 0);
    $X->QueryPointer($X->root); # flush and sync


    $X2->GrabServer;
    $X2->QueryPointer($X->root); # sync

    my $reply;
    my $seq = $X->send('QueryPointer',$X->root);
    $X->add_reply ($seq, \$reply);
    $X->flush;

    $X2->QueryPointer($X->root); # sync

    while (fh_readable ($X->{'connection'}->fh)) {
      ### X handle_input ...
      $X->handle_input;
    }
    ### $reply
    my $got_impervious = (defined $reply ? 1 : 0);

    $X2->UngrabServer;
    $X2->QueryPointer($X->root); # sync
    $X->QueryPointer($X->root); # sync
    ### $reply

    ok ($got_impervious,
        $want_impervious,
        'impervious');
  }
}

# return true if file handle $fh has data ready to read
sub fh_readable {
  my ($fh) = @_;
  require IO::Select;
  my $s = IO::Select->new;
  $s->add($fh);
  my @ready = $s->can_read(1);
  return scalar(@ready);
}

#------------------------------------------------------------------------------

exit 0;
