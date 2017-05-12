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

use strict;
use Time::Duration::Locale ();
use Test::More tests => 20;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

ok (! defined &duration, 'duration() should not be imported');
ok (! defined &ago,      'ago() should not be imported');
ok (! defined &AUTOLOAD, 'AUTOLOAD() should not be imported');
ok (! defined &can,      'can() should not be imported');

cmp_ok (Time::Duration::Locale::duration(1), 'ne', '',
        'duration(1)');
cmp_ok (Time::Duration::Locale::duration(1,1), 'ne', '',
        'duration(1,1)');
cmp_ok (Time::Duration::Locale::duration_exact(1), 'ne', '',
        'duration(1)');

cmp_ok (Time::Duration::Locale::ago(1), 'ne', '',
        'ago(1)');
cmp_ok (Time::Duration::Locale::ago(1,1), 'ne', '',
        'ago(1,1)');
cmp_ok (Time::Duration::Locale::ago_exact(1), 'ne', '',
        'ago(1)');

cmp_ok (Time::Duration::Locale::from_now(1), 'ne', '',
        'from_now(1)');
cmp_ok (Time::Duration::Locale::from_now(1,1), 'ne', '',
        'from_now(1,1)');
cmp_ok (Time::Duration::Locale::from_now_exact(1), 'ne', '',
        'from_now(1)');

cmp_ok (Time::Duration::Locale::later(1), 'ne', '',
        'later(1)');
cmp_ok (Time::Duration::Locale::later(1,1), 'ne', '',
        'later(1,1)');
cmp_ok (Time::Duration::Locale::later_exact(1), 'ne', '',
        'later(1)');

cmp_ok (Time::Duration::Locale::earlier(1), 'ne', '',
        'earlier(1)');
cmp_ok (Time::Duration::Locale::earlier(1,1), 'ne', '',
        'earlier(1,1)');
cmp_ok (Time::Duration::Locale::earlier_exact(1), 'ne', '',
        'earlier(1)');

cmp_ok (Time::Duration::Locale::concise(Time::Duration::Locale::duration(123)),
        'ne', '',
        'concise(duration(123))');

exit 0;
