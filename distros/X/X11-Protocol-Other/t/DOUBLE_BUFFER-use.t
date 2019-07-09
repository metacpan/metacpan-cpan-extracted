#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2017 Kevin Ryde

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

## no critic (RequireUseStrict, RequireUseWarnings)
use X11::Protocol::Ext::DOUBLE_BUFFER;

use Test;
BEGIN { plan tests => 7 }
ok (1, 1, 'X11::Protocol::Ext::DOUBLE_BUFFER load as first thing');


#------------------------------------------------------------------------------
# VERSION

my $want_version = 31;
ok ($X11::Protocol::Ext::DOUBLE_BUFFER::VERSION,
    $want_version,
    'VERSION variable');
ok (X11::Protocol::Ext::DOUBLE_BUFFER->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { X11::Protocol::Ext::DOUBLE_BUFFER->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { X11::Protocol::Ext::DOUBLE_BUFFER->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# CLIENT_MAJOR_VERSION / CLIENT_MINOR_VERSION

ok (X11::Protocol::Ext::DOUBLE_BUFFER::CLIENT_MAJOR_VERSION(), 1,
    'CLIENT_MAJOR_VERSION');
ok (X11::Protocol::Ext::DOUBLE_BUFFER::CLIENT_MINOR_VERSION(), 0,
    'CLIENT_MINOR_VERSION');


exit 0;
