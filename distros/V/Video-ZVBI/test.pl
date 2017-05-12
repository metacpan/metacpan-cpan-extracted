#!/usr/bin/perl -w
#
# Copyright (C) 2007 Tom Zoerner.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# For a copy of the GPL refer to <http://www.gnu.org/licenses/>
#
# $Id: test.pl,v 1.2 2007/12/02 18:43:53 tom Exp tom $
#

use blib;
use Video::ZVBI;

# Well, so far we only test if the module loads correctly.
# For manual testing, see the examples/ sub-directory.

print "OK module booted, library version ".
      join('.', Video::ZVBI::lib_version()) ."\n";

1;

