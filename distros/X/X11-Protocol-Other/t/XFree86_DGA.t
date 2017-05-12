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

my $screen_num = MyTestHelpers::X11_chosen_screen_number($X);


#------------------------------------------------------------------------------
# "XF86DGA" errors

{
  ok ($X->num('Error','XF86DGAClientNotLocal'),        $first_error);
  ok ($X->num('Error','XF86DGANoDirectVideoMode'),     $first_error+1);
  ok ($X->num('Error','XF86DGAScreenNotActive'),       $first_error+2);
  ok ($X->num('Error','XF86DGADirectNotActivated'),    $first_error+3);
  ok ($X->num('Error',$first_error),   $first_error);
  ok ($X->num('Error',$first_error+3), $first_error+3);
  ok ($X->interp('Error',$first_error), 'XF86DGAClientNotLocal');
  ok ($X->interp('Error',$first_error+1), 'XF86DGANoDirectVideoMode');
  ok ($X->interp('Error',$first_error+2), 'XF86DGAScreenNotActive');
  ok ($X->interp('Error',$first_error+3), 'XF86DGADirectNotActivated');

  {
    local $X->{'do_interp'} = 0;
    ok ($X->interp('Error',$first_error),   $first_error);
    ok ($X->interp('Error',$first_error+3), $first_error+3);
  }
}


#------------------------------------------------------------------------------
# XF86DGAQueryVersion()

{
  my @ret = $X->XF86DGAQueryVersion;
  MyTestHelpers::diag ("server XFree86_DGA version ", join('.',@ret));
  ok (scalar(@ret), 2);
  $X->QueryPointer($X->root); # sync
}


#------------------------------------------------------------------------------
# XF86DGAQueryDirectVideo()

my $direct_video_available;
{
  my $flags = $X->XF86DGAQueryDirectVideo($screen_num);
  MyTestHelpers::diag ("XF86DGAQueryDirectVideo flags=$flags in hex ",
                       sprintf('%X',$flags));
  ok ($flags =~ /^\d+$/, 1);
  $direct_video_available = $flags & 1;
  $X->QueryPointer($X->root); # sync
}

my $skip_if_no_direct_video;
if (! $direct_video_available) {
  $skip_if_no_direct_video = 'no direct video available';
}


#------------------------------------------------------------------------------
# XF86DGAGetVideoLL()
#
# Have seen an x.org server on solaris give flags=1 from
# XF86DGAQueryDirectVideo() but then error XF86DGANoDirectVideoMode from an
# attempt at XF86DGAGetVideoLL().  So watch for an error here, not just from
# $direct_video_available.

{
  my $error;
  my $orig_error_handler = $X->{'error_handler'};
  local $X->{'error_handler'} = sub {
    my ($X, $data) = @_;
    ### error handler
    ### $data

    my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;
    my $typename = $X->interp('Error',$type);
    MyTestHelpers::diag ("XF86DGAGetVideoLL error $typename");
    $error = $typename;
    $direct_video_available = 0;
    $skip_if_no_direct_video = 'error from XF86DGAGetVideoLL';
    die "longjmp out to eval";

    # if ($typename =~ /^XF86DGA/) {
    # } else {
    #   goto $orig_error_handler;
    # }
  };

  my $skip = $skip_if_no_direct_video;
  my @ret;
  if ($direct_video_available) {
    if (eval {
      @ret = $X->XF86DGAGetVideoLL($screen_num);
      1;
    }) {
      MyTestHelpers::diag ("XF86DGAGetVideoLL ", join(', ',@ret));
      MyTestHelpers::diag ("  in hex ", join(', ',map{sprintf '%X',$_}@ret));
    } else {
      MyTestHelpers::diag ("XF86DGAGetVideoLL error: ",$@);
    }
    $X->QueryPointer($X->root); # sync
  }
  if (defined $error) {
    $skip = 'due to XF86DGAGetVideoLL error reply';
  }
  skip ($skip, scalar(@ret), 4);
}


#------------------------------------------------------------------------------
# XF86DGAGetViewPortSize

{
  my @ret;
  if ($direct_video_available) {
    @ret = $X->XF86DGAGetViewPortSize($screen_num);
    MyTestHelpers::diag ("XF86DGAGetViewPortSize ", join(', ',@ret));
    $X->QueryPointer($X->root); # sync
  }
  skip ($skip_if_no_direct_video,
        scalar(@ret), 2);
}


#------------------------------------------------------------------------------
# XF86DGAGetVidPage()

{
  my $page = '';
  if ($direct_video_available) {
    $page = $X->XF86DGAGetVidPage($screen_num);
    MyTestHelpers::diag ("XF86DGAGetVidPage ", $page);
    $X->QueryPointer($X->root); # sync
  }
  skip ($skip_if_no_direct_video,
        $page =~ /^\d+$/, 1);
}


#------------------------------------------------------------------------------
# XF86DGADirectVideo()

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
# XF86DGAGetVidPage() / XF86DGASetVidPage()

{
  my $old_page = $X->XF86DGAGetVidPage($screen_num);
  my $new_page = 0;
  my $got_page;
  if ($enabled) {
    $X->XF86DGASetVidPage ($screen_num, $new_page);
    $got_page = $X->XF86DGAGetVidPage($screen_num);
    $X->QueryPointer($X->root); # sync
  }
  skip ($skip_if_not_enabled,
        $got_page, $new_page,
        'XF86DGASetVidPage page');
}

#------------------------------------------------------------------------------
# XF86DGASetViewPort()

{
  if ($enabled) {
    $X->XF86DGASetViewPort($screen_num, 0,0);
    $X->QueryPointer($X->root); # sync
  }
  skip ($skip_if_not_enabled,
        1,1, 'XF86DGASetViewPort');
}

#------------------------------------------------------------------------------
# XF86DGAInstallColormap()

{
  my $colormap = $X->default_colormap;
  if ($enabled) {
    $X->XF86DGAInstallColormap($screen_num, $colormap);
    $X->QueryPointer($X->root); # sync
  }
  skip ($skip_if_not_enabled,
        1,1, 'XF86DGAInstallColormap');
}

#------------------------------------------------------------------------------
# XF86DGAViewPortChanged()

{
  my $bool = 'x';
  if ($enabled) {
    $bool = $X->XF86DGAViewPortChanged($screen_num);
    MyTestHelpers::diag ("XF86DGAViewPortChanged ", $bool);
    $X->QueryPointer($X->root); # sync
  }
  skip ($skip_if_not_enabled,
        $bool =~ /^\d+$/, 1,
        'XF86DGAViewPortChanged return');
}

#------------------------------------------------------------------------------

exit 0;
