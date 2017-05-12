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

use 5.004;
use strict;
use Time::Duration::en_PIGLATIN ();
use Test::More tests => 7;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

ok (! defined &duration, 'duration() should not be imported');
ok (! defined &ago,      'ago() should not be imported');
ok (! defined &AUTOLOAD, 'AUTOLOAD() should not be imported');
ok (! defined &can,      'can() should not be imported');

is (Time::Duration::en_PIGLATIN::duration(1), '1 econdsay');
my $subr = Time::Duration::en_PIGLATIN->can('ago');
ok ($subr, 'can(ago)');
is ($subr->(2), '2 econdssay agoway');

exit 0;
