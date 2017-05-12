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


use lib 'devel/lib';
$ENV{'DISPLAY'} ||= ":0";





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
  = $X->QueryExtension('XFree86-VidModeExtension');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no XFree86-VidModeExtension on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("XFree86-VidModeExtension extension opcode=$major_opcode event=$first_event error=$first_error");
}

require X11::Protocol::Ext::XFree86_VidModeExtension;

if (! $X->init_extension ('XFree86-VidModeExtension')) {
  die "QueryExtension says XFree86-VidModeExtension avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync




#------------------------------------------------------------------------------
# "XF86VidMode" errors

{
  ok ($X->num('Error','XF86VidModeBadClock'),          $first_error);
  ok ($X->num('Error','XF86VidModeBadHTimings'),       $first_error+1);
  ok ($X->num('Error','XF86VidModeBadVTimings'),       $first_error+2);
  ok ($X->num('Error','XF86VidModeModeUnsuitable'),    $first_error+3);
  ok ($X->num('Error','XF86VidModeExtensionDisabled'), $first_error+4);
  ok ($X->num('Error','XF86VidModeClientNotLocal'),    $first_error+5);
  ok ($X->num('Error','XF86VidModeZoomLocked'),        $first_error+6);
  ok ($X->num('Error',$first_error),   $first_error);
  ok ($X->num('Error',$first_error+6), $first_error+6);
  ok ($X->interp('Error',$first_error),   'XF86VidModeBadClock');
  ok ($X->interp('Error',$first_error+1), 'XF86VidModeBadHTimings');
  ok ($X->interp('Error',$first_error+2), 'XF86VidModeBadVTimings');
  ok ($X->interp('Error',$first_error+3), 'XF86VidModeModeUnsuitable');
  ok ($X->interp('Error',$first_error+4), 'XF86VidModeExtensionDisabled');
  ok ($X->interp('Error',$first_error+5), 'XF86VidModeClientNotLocal');
  ok ($X->interp('Error',$first_error+6), 'XF86VidModeZoomLocked');

  {
    local $X->{'do_interp'} = 0;
    ok ($X->interp('Error',$first_error),   $first_error);
    ok ($X->interp('Error',$first_error+3), $first_error+3);
  }
}


#------------------------------------------------------------------------------
# XF86VidModeQueryVersion

{
  my @ret = $X->XF86VidModeQueryVersion;
  MyTestHelpers::diag ("server XFree86_VidModeExtension version ", join('.',@ret));
  ok (scalar(@ret), 2);
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XF86VidModeGetModeLine

{
  my @ret = $X->XF86VidModeGetModeLine(0);
  MyTestHelpers::diag ("XF86VidModeGetModeLine ",
                       join(' ',@ret[0..$#ret-2])); # not "private" bytes
  ok ($ret[0],  'dotclock');
  ok ($ret[1] =~ /^\d+$/, 1);
  ok ($ret[-2], 'private');
}
$X->QueryPointer($X->root); # sync


# #------------------------------------------------------------------------------
# # XF86VidModeGetVideoLL
# #
# # Have seen an x.org server on solaris give flags=1 from
# # XF86VidModeQueryDirectVideo() but then error XF86VidModeNoDirectVideoMode from an
# # attempt at XF86VidModeGetVideoLL().  So watch for an error here, not just from
# # $direct_video_available.
# 
# {
#   my $error;
#   my $orig_error_handler = $X->{'error_handler'};
#   local $X->{'error_handler'} = sub {
#     my ($X, $data) = @_;
#     ### error handler
#     ### $data
# 
#     my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;
#     my $typename = $X->interp('Error',$type);
#     if ($typename =~ /^XF86VidMode/) {
#       MyTestHelpers::diag ("XF86VidModeGetVideoLL error $typename");
#       $error = $typename;
#       $direct_video_available = 0;
#       $skip_if_no_direct_video = 'error from XF86VidModeGetVideoLL';
#       die "longjmp out to eval";
#     } else {
#       goto $orig_error_handler;
#     }
#   };
# 
#   my @ret;
#   if ($direct_video_available) {
#     if (eval {
#       @ret = $X->XF86VidModeGetVideoLL(0);
#       1;
#     }) {
#       MyTestHelpers::diag ("XF86VidModeGetVideoLL ", join(', ',@ret));
#       MyTestHelpers::diag ("  in hex ", join(', ',map{sprintf '%X',$_}@ret));
#     }
#   }
#   my $skip_if_error = (defined $error
#                        ? 'due to XF86VidModeGetVideoLL error reply'
#                        : undef);
#   skip ($skip_if_error,
#         scalar(@ret), 4);
# }
# $X->QueryPointer($X->root); # sync
# 
# 
# #------------------------------------------------------------------------------
# # XF86VidModeGetViewPortSize
# 
# {
#   my @ret;
#   if ($direct_video_available) {
#     @ret = $X->XF86VidModeGetViewPortSize(0);
#     MyTestHelpers::diag ("XF86VidModeGetViewPortSize ", join(', ',@ret));
#   }
#   skip ($skip_if_no_direct_video,
#         scalar(@ret), 2);
# }
# $X->QueryPointer($X->root); # sync
# 
# 
# #------------------------------------------------------------------------------
# # XF86VidModeGetVidPage
# 
# {
#   my $page = '';
#   if ($direct_video_available) {
#     $page = $X->XF86VidModeGetVidPage(0);
#     MyTestHelpers::diag ("XF86VidModeGetVidPage ", $page);
#   }
#   skip ($skip_if_no_direct_video,
#         $page =~ /^\d+$/, 1);
# }
# $X->QueryPointer($X->root); # sync
# 
# 
# #------------------------------------------------------------------------------
# # XF86VidModeDirectVideo
# 
# my $enabled = 1;
# {
#   my $orig_error_handler = $X->{'error_handler'};
#   local $X->{'error_handler'} = sub {
#     my ($X, $data) = @_;
#     ### error handler
#     ### $data
# 
#     my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;
#     my $typename = $X->interp('Error',$type);
#     if ($typename =~ /^XF86VidMode/) {
#       MyTestHelpers::diag ("XF86VidModeDirectVideo error $typename");
#       $enabled = 0;
#     } else {
#       goto $orig_error_handler;
#     }
#   };
# 
#   MyTestHelpers::diag ("XF86VidModeDirectVideo attempt ...");
#   $X->XF86VidModeDirectVideo(0, 0x02);
#   $X->QueryPointer($X->root); # sync
#   MyTestHelpers::diag ("XF86VidModeDirectVideo done");
# }
# 
# my $skip_if_not_enabled;
# if ($enabled) {
#   MyTestHelpers::diag ('DirectVideo enabled');
# } else {
#   MyTestHelpers::diag ('DirectVideo not enabled');
#   $skip_if_not_enabled = 'skip due to DirectVideo not enabled';
# }
# 
# #------------------------------------------------------------------------------
# # XF86VidModeGetVidPage / XF86VidModeSetVidPage
# 
# {
#   my $old_page = $X->XF86VidModeGetVidPage(0);
#   my $new_page = 0;
#   my $got_page;
#   if ($enabled) {
#     $X->XF86VidModeSetVidPage (0, 0);
#     $got_page = $X->XF86VidModeGetVidPage(0);
#   }
#   skip ($skip_if_not_enabled,
#         $got_page, $new_page,
#         'XF86VidModeSetVidPage page');
# }
# $X->QueryPointer($X->root); # sync
# 
# #------------------------------------------------------------------------------
# # XF86VidModeSetViewPort
# 
# {
#   if ($enabled) {
#     $X->XF86VidModeSetViewPort(0, 0,0);
#     $X->QueryPointer($X->root); # sync
#   }
#   skip ($skip_if_not_enabled,
#         1,1, 'XF86VidModeInstallColormap');
# }
# 
# #------------------------------------------------------------------------------
# # XF86VidModeInstallColormap
# 
# {
#   my $colormap = $X->default_colormap;
#   if ($enabled) {
#     $X->XF86VidModeInstallColormap(0, $colormap);
#   }
#   skip ($skip_if_not_enabled,
#         1,1, 'XF86VidModeInstallColormap');
# }
# $X->QueryPointer($X->root); # sync
# 
# 
# #------------------------------------------------------------------------------
# # XF86VidModeViewPortChanged
# 
# {
#   my $bool = 'x';
#   if ($enabled) {
#     $bool = $X->XF86VidModeViewPortChanged(0);
#     MyTestHelpers::diag ("XF86VidModeViewPortChanged ", $bool);
#   }
#   skip ($skip_if_not_enabled,
#         $bool =~ /^\d+$/, 1,
#         'XF86VidModeViewPortChanged return');
# }
# $X->QueryPointer($X->root); # sync

#------------------------------------------------------------------------------

exit 0;
