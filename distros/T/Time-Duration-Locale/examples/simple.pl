#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.


# Simply "use Time::Duration::Locale" instead of "use Time::Duration" and
# the duration() etc functions follow your LANGUAGE.  Try
#
#     LANGUAGE=sv perl simple.pl
#
# Or if you don't have sv then the supplied silliness of
#
#     LANGUAGE=en_PIGLATIN perl simple.pl


use strict;
use Time::Duration::Locale;

print "next update is after ",duration(120),"\n";
print "the previous update was ",ago(90),"\n";
exit 0;
