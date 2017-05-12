#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./tie-tz.pl
#

use strict;
use warnings;
use Tie::TZ qw($TZ);
use POSIX ('ctime');

print "Default: ", ctime(time());

$TZ = 'GMT';
print "GMT:     ", ctime(time());

$TZ = 'FOO+10';
print "FOO+10:  ", ctime(time());

{ local $TZ = 'BAR-10';
  print "BAR-10:  ", ctime(time());
}

# and $TZ is restored automatically outside the "local", so back to FOO+10
print "FOO+10:  ", ctime(time());

exit 0;
