#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

use 5.004;
use strict;

{
  package Encode::MyEncoding;
  use strict;
  use Carp;
  use base 'Encode::Encoding';

  __PACKAGE__->Define('X11-Compound-Text');

  sub encode {
    my ($self, $str, $check) = @_;
  }

  sub decode {
    my ($self, $bytes, $check) = @_;
    croak "Not implemented yet";
  }
}
