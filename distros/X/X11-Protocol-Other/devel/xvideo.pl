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


use strict;
use X11::Protocol;

# uncomment this to run the ### lines
use Smart::Comments;


my $X = X11::Protocol->new (':0');
$X->init_extension('XVideo') or die $@;

{
  require UUID;
  my @version = $X->XVideoQueryExtension;
  ### @version

  my $window = $X->root;
  my @adaptors = $X->XVideoQueryAdaptors($window);
  ### @adaptors


  foreach my $adaptor (@adaptors) {
    foreach my $port ($adaptor->{'port_base'}
                      .. $adaptor->{'port_base'} + $adaptor->{'num_ports'}-1) {
      ### $port

      my @encodings = $X->XVideoQueryEncodings($port);
      ### @encodings
      
      my @formats = $X->XVideoListImageFormats($port);
      ### @formats
      foreach my $format (@formats) {
        my $bytes = $format->{'guid'};
        my $uuidstr;
        UUID::unparse($bytes, $uuidstr);
        ### $uuidstr
      }

      my @attributes = $X->XVideoQueryPortAttributes($port);
      ### @attributes
      
      my $value = $X->XVideoGetPortAttribute($port, $X->atom('XV_ENCODING'));
      ### $value
      
    }
  }

  exit 0;
}


