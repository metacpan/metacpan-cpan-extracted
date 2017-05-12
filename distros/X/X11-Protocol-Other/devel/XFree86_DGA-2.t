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


my $test_count = (tests => 21)[1];
plan tests => $test_count;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $have_extension = 0;

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
  = $X->QueryExtension('XFree86-DGA');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no XFree86-DGA on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("XFree86-DGA extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('XFree86-DGA')) {
  die "QueryExtension says XFree86-DGA avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

{
  my $want_major = 2;
  my $want_minor = 0;
  my ($server_major, $server_minor) = $X->XF86DGAQueryVersion();
  MyTestHelpers::diag ("XF86DGAQueryVersion() got server version $server_major.$server_minor");
  if ((($want_major <=> $server_major) || ($want_minor <=> $server_minor))
      < 0) {
    foreach (1 .. $test_count) {
      skip ("QueryVersion() no XFree86-DGA $want_major.$want_minor on the server", 1, 1);
    }
    exit 0;
  }
}

END {
  if ($have_extension) {
    MyTestHelpers::diag ("cleanup, XF86DGADirectVideo disable");
    local $X->{'error_handler'} = sub {
      my ($X, $data) = @_;
      my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;
      MyTestHelpers::diag ("  ignore error in cleanup: ",$type);
    };
    $X->XF86DGADirectVideo (0, 0); # disable
    $X->QueryPointer($X->root); # sync
    MyTestHelpers::diag ("  done XF86DGADirectVideo disable");
  }
}
$have_extension = 1;


#------------------------------------------------------------------------------
# _hilo_to_card64()

ok (X11::Protocol::Ext::XFree86_DGA::_hilo_to_card64(0,1),
    1);
ok (X11::Protocol::Ext::XFree86_DGA::_hilo_to_card64(0,0x8000_0000),
    2147483648);
ok (X11::Protocol::Ext::XFree86_DGA::_hilo_to_card64(0,0xFFFF_FFFF),
    4294967295);

ok (X11::Protocol::Ext::XFree86_DGA::_hilo_to_card64(0x8000_0000,3) . '',
    '9223372036854775811');
ok (X11::Protocol::Ext::XFree86_DGA::_hilo_to_card64(0x1234_5678, 0x8765_4321) . '',
    '1311768467139281697');

ok (X11::Protocol::Ext::XFree86_DGA::_hilo_to_card64(0xFFFF_FFFF, 0xFFFF_FFFF) . '',
    '18446744073709551615');

#------------------------------------------------------------------------------

my $screen_num = MyTestHelpers::X11_chosen_screen_number($X);

my $direct_video_available;
{
  my $flags = $X->XF86DGAQueryDirectVideo(0);
  MyTestHelpers::diag ("XF86DGAQueryDirectVideo flags=$flags in hex ",
                       sprintf('%X',$flags));
  ok ($flags =~ /^\d+$/, 1);
  $direct_video_available = $flags & 1;
}
$X->QueryPointer($X->root); # sync

my $skip_if_no_direct_video;
if (! $direct_video_available) {
  $skip_if_no_direct_video = 'no direct video available';
}


#------------------------------------------------------------------------------
# XDGASetClientVersion()

$X->XDGASetClientVersion(2,0);
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XDGAQueryModes()

my $first_mode;
{
  my @ret;
  if ($direct_video_available) {
    @ret = $X->XDGAQueryModes($screen_num);
  }
  skip ($skip_if_no_direct_video,
        scalar(@ret) & 1, 0);
  $first_mode = $ret[0];
}

#------------------------------------------------------------------------------
# XF86DGADirectVideo()  enable

my $enabled = 1;
{
  my $orig_error_handler = $X->{'error_handler'};
  local $X->{'error_handler'} = sub {
    my ($X, $data) = @_;
    ### error handler
    ### $data

    my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;
    my $typename = $X->interp('Error',$type);
    if ($typename =~ /^XF86DGA/) {
      MyTestHelpers::diag ("XF86DGADirectVideo error $typename");
      $enabled = 0;
    } else {
      goto $orig_error_handler;
    }
  };

  MyTestHelpers::diag ("XF86DGADirectVideo attempt ...");
  $X->XF86DGADirectVideo($screen_num, 0x02);
  $X->QueryPointer($X->root); # sync
  MyTestHelpers::diag ("XF86DGADirectVideo done");
}

my $skip_if_not_enabled;
if ($enabled) {
  MyTestHelpers::diag ('DirectVideo enabled');
} else {
  MyTestHelpers::diag ('DirectVideo not enabled');
  $skip_if_not_enabled = 'skip due to DirectVideo not enabled';
}

#------------------------------------------------------------------------------
# XDGAQueryModes()

#------------------------------------------------------------------------------
# XDGASetMode()

#------------------------------------------------------------------------------
# XDGASetViewport()

if ($enabled) { # Must activate first.
  $X->XDGASetViewport($screen_num, 0,0, 0);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XDGAInstallColormap()

if ($enabled) { # Must activate first.
  my $colormap = $X->default_colormap;
  $X->XDGAInstallColormap($screen_num, $colormap);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XDGASelectInput()

if ($enabled) { # Must activate first.
  $X->XDGASelectInput($screen_num,0);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XDGAFillRectangle()

if ($enabled) { # Must activate first.
  $X->XDGAFillRectangle($screen_num, 0,0, 16,16, 0);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XDGACopyArea()

if ($enabled) { # Must activate first.
  $X->XDGACopyArea($screen_num,
                   16,0,   # src
                   16,16, # w,h
                   0,0); # dst
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XDGACopyTransparentArea()

# FIXME: what is the key?
# Only if DGA_BLIT_RECT_TRANS ?
#
# if ($enabled) { # Must activate first.
#   $X->XDGACopyTransparentArea($screen_num,
#                               32,0,   # src
#                               16,16,  # w,h
#                               32,16,  # dst
#                               0);     # key
#   $X->QueryPointer($X->root); # sync
# }

#------------------------------------------------------------------------------
# XDGAGetViewportStatus()

{
  my @ret;
  if ($direct_video_available) {
    @ret = $X->XDGAGetViewportStatus($screen_num);
    MyTestHelpers::diag ("XDGAGetViewportStatus ", join(', ',@ret));
  }
  skip ($skip_if_no_direct_video,
        scalar(@ret), 1);

  # my ($device_name, $addr, $size, $offset, $extra) = @ret;
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XDGASync()

if ($enabled) { # Must activate first.
  $X->XDGASync($screen_num);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XDGAOpenFramebuffer()

{
  my @ret;
  if ($direct_video_available) {
    @ret = $X->XDGAOpenFramebuffer($screen_num);
    MyTestHelpers::diag ("XDGAOpenFramebuffer ", join(', ',@ret));
  }
  skip ($skip_if_no_direct_video,
        scalar(@ret), 5);

  # my ($device_name, $addr, $size, $offset, $extra) = @ret;
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XDGACloseFramebuffer()

if ($direct_video_available) {
  $X->XDGACloseFramebuffer($screen_num);
  $X->QueryPointer($X->root); # sync
}


#------------------------------------------------------------------------------
# XDGAChangePixmapMode()

{
  my @ret;
  if ($direct_video_available) {
    @ret = $X->XDGAChangePixmapMode($screen_num,0,0);
    $X->QueryPointer($X->root); # sync
  }
  skip ($skip_if_no_direct_video,
        scalar(@ret), 2);
}

#------------------------------------------------------------------------------
# XDGACreateColormap()

if ($enabled) {
  my $colormap = $X->new_rsrc;
  my $alloc = 0;
  $X->XDGACreateColormap ($screen_num, $colormap, $first_mode, $alloc);
  $X->QueryPointer($X->root); # sync

  $X->FreeColormap($colormap);
  $X->QueryPointer($X->root); # sync
}


#------------------------------------------------------------------------------
# XDGASetClientVersion()

#------------------------------------------------------------------------------
# XDGASetClientVersion()

#------------------------------------------------------------------------------
# XDGASetClientVersion()

#------------------------------------------------------------------------------
# XDGASetClientVersion()


#------------------------------------------------------------------------------

exit 0;
__END__


# XF86DGAGetVidPage

{
  my $page = '';
  if ($direct_video_available) {
    $page = $X->XF86DGAGetVidPage(0);
    MyTestHelpers::diag ("XF86DGAGetVidPage ", $page);
  }
  skip ($skip_if_no_direct_video,
        $page =~ /^\d+$/, 1);
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XF86DGADirectVideo

my $enabled = 1;
{
  my $orig_error_handler = $X->{'error_handler'};
  local $X->{'error_handler'} = sub {
    my ($X, $data) = @_;
    ### error handler
    ### $data

    my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;
    my $typename = $X->interp('Error',$type);
    if ($typename =~ /^XF86DGA/) {
      MyTestHelpers::diag ("XF86DGADirectVideo error $typename");
      $enabled = 0;
    } else {
      goto $orig_error_handler;
    }
  };

  MyTestHelpers::diag ("XF86DGADirectVideo attempt ...");
  $X->XF86DGADirectVideo(0, 0x02);
  $X->QueryPointer($X->root); # sync
  MyTestHelpers::diag ("XF86DGADirectVideo done");
}

my $skip_if_not_enabled;
if ($enabled) {
  MyTestHelpers::diag ('DirectVideo enabled');
} else {
  MyTestHelpers::diag ('DirectVideo not enabled');
  $skip_if_not_enabled = 'skip due to DirectVideo not enabled';
}

#------------------------------------------------------------------------------
# XF86DGAGetVidPage / XF86DGASetVidPage

{
  my $old_page = $X->XF86DGAGetVidPage(0);
  my $new_page = 0;
  my $got_page;
  if ($enabled) {
    $X->XF86DGASetVidPage (0, 0);
    $got_page = $X->XF86DGAGetVidPage(0);
  }
  skip ($skip_if_not_enabled,
        $got_page, $new_page,
        'XF86DGASetVidPage page');
}
$X->QueryPointer($X->root); # sync

#------------------------------------------------------------------------------
# XF86DGASetViewPort

{
  if ($enabled) {
    $X->XF86DGASetViewPort(0, 0,0);
    $X->QueryPointer($X->root); # sync
  }
  skip ($skip_if_not_enabled,
        1,1, 'XF86DGAInstallColormap');
}

#------------------------------------------------------------------------------
# XF86DGAInstallColormap

{
  my $colormap = $X->default_colormap;
  if ($enabled) {
    $X->XF86DGAInstallColormap(0, $colormap);
  }
  skip ($skip_if_not_enabled,
        1,1, 'XF86DGAInstallColormap');
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XF86DGAViewPortChanged

{
  my $bool = 'x';
  if ($enabled) {
    $bool = $X->XF86DGAViewPortChanged(0);
    MyTestHelpers::diag ("XF86DGAViewPortChanged ", $bool);
  }
  skip ($skip_if_not_enabled,
        $bool =~ /^\d+$/, 1,
        'XF86DGAViewPortChanged return');
}
$X->QueryPointer($X->root); # sync

#------------------------------------------------------------------------------

exit 0;
