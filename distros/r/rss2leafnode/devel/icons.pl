#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use LWP::UserAgent;
use List::Util 'max','min';
use POSIX ();
use Locale::TextDomain 1.17;
use Locale::TextDomain ('App-RSS2Leafnode');

use Smart::Comments;

{
  require Image::Magick;
  open my $fh, '<', '/tmp/favicon.ico' or die;
  my $bytes = do { local $/; <$fh> }; # slurp
  close $fh or die;

  my $im = Image::Magick->new (magick => 'ico');
  my @info = $im->Ping(blob=>$bytes);
  ### @info
  @info = $im->Ping('/tmp/xx');
  ### @info
  @info = $im->Ping('/tmp/favicon.ico');
  ### @info
  exit 0;
}

{
  require Image::Magick;
  my $im = Image::Magick->new;
  # $im->Read('/usr/share/icons/hicolor/48x48/apps/emacs.png');
  my $ret = $im->Read('/tmp/favicon.icoxxy');
  ### $ret

  # open my $fh, '<', '/tmp/favicon.ico' or die;
  # my $bytes = do { local $/; <$fh> }; # slurp
  # close $fh or die;

  # my $im = Image::Magick->new (mime=>'image/x-icon');
  # # $im->Set(mime=>'image/x-ico');
  # # 'image/vnd.microsoft.icon'
  # # my $im = Image::Magick->new (magick=>'ico');
  # my $ret = $im->BlobToImage ($bytes);
  # ### $ret

  # $im->Set(magick => 'xbm');
  # # $im->Set(-compress => 'none');
  # $im->Write('/tmp/x.xbm');
  # system('cat /tmp/x.xbm');
  exit 0;
}

{
  require Image::Pngslimmer;
  open my $fh, '<', '/usr/share/icons/hicolor/48x48/apps/emacs.png' or die;
  my $bytes = do { local $/; <$fh> }; # slurp
  close $fh or die;
  ### before: length($bytes)
  $bytes = Image::Pngslimmer::zlibshrink($bytes);
  ### after: length($bytes)
  exit 0;
}


my $ua = LWP::UserAgent->new;
{
  my $self = bless({verbose=>2},'main');
  #my $url = 'file:///usr/share/emacs/22.3/etc/images/icons/emacs_32.png';
  # my $url = 'file:///tmp/x.jpg';
  #my $url = 'file:///usr/share/icons/hicolor/64x64/apps/xtide.png';
  my $url = 'file:///usr/share/icons/hicolor/48x48/apps/emacs.png';
  $self->download_face($url, 0, 0);
  exit 0;
}
{
  my $self = bless({verbose=>2},'main');
  my $url = "file://$ENV{HOME}/tux/web/ch"."art/index.html";
  my $resp = $ua->get($url);
  ### favicon: resp_favicon_uri($resp)
  ### face: $self->resp_face($resp)
  exit 0;
}

# sub image_size {
#   if (eval { require Image::ExifTool }) {
#   } elsif (eval { require Image::Magick }) {
# }

sub imagemagick_to_x_face {
  my ($self, $type, $data) = @_;
  eval { require Image::XFace } or return;
  ### $type
  my $image = $self->imagemagick_from_data($type,$data) || return;
  # $xface = Image::XFace::compface(@bits);
  return;
}

