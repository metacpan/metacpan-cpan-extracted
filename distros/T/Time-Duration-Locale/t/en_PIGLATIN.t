#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2013, 2016 Kevin Ryde

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
use Time::Duration::en_PIGLATIN;
use Test::More tests => 33;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $want_version = 12;
is ($Time::Duration::en_PIGLATIN::VERSION, $want_version,
    'VERSION variable');
is (Time::Duration::en_PIGLATIN->VERSION, $want_version,
    'VERSION class method');
{ ok (eval { Time::Duration::en_PIGLATIN->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Time::Duration::en_PIGLATIN->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

# $ENV{'LANGUAGE'} = 'en';
# Time::Duration::en_PIGLATIN::setlocale();
# is (Time::Duration::en_PIGLATIN::module(), 'Time::Duration');


{
  my $can = Time::Duration::en_PIGLATIN->can('duration');
  ok ($can, 'can(duration) true');
  is ($can && ref $can, 'CODE', 'can(duration) is a coderef');
  cmp_ok (&$can(1), 'ne', '', ' can(duration) call');
}

{
  my $can = Time::Duration::en_PIGLATIN->can('nosuchfunctionnameexists');
  is ($can, undef, 'can(nosuchfunctionnameexists) undef');
}

is (duration(1), '1 econdsay', 'duration(1)');
cmp_ok (duration(1,1), 'ne', '',
        'duration(1,1)');
cmp_ok (duration_exact(1), 'ne', '',
        'duration(1)');

is (ago(2), '2 econdssay agoway', 'ago(2)');
cmp_ok (ago(1,1), 'ne', '',
        'ago(1,1)');
cmp_ok (ago_exact(1), 'ne', '',
        'ago(1)');

cmp_ok (from_now(1), 'ne', '',
        'from_now(1)');
cmp_ok (from_now(1,1), 'ne', '',
        'from_now(1,1)');
cmp_ok (from_now_exact(1), 'ne', '',
        'from_now(1)');

cmp_ok (later(1), 'ne', '',
        'later(1)');
cmp_ok (later(1,1), 'ne', '',
        'later(1,1)');
cmp_ok (later_exact(1), 'ne', '',
        'later(1)');

cmp_ok (earlier(1), 'ne', '',
        'earlier(1)');
cmp_ok (earlier(1,1), 'ne', '',
        'earlier(1,1)');
cmp_ok (earlier_exact(1), 'ne', '',
        'earlier(1)');

cmp_ok (concise(duration(123)), 'ne', '',
        'concise(duration(123))');

#------------------------------------------------------------------------------
# "No such function"

{
  my $ret = eval { Time::Duration::en_PIGLATIN::testnosuchfunction(); 1 };
  my $error = $@;
  ok (! $ret, 'testnosuchfunction() fails');
  like ($error, '/^No function testnosuchfunction exported by Time::Duration/',
      'testnosuchfunction() error message');
}

#------------------------------------------------------------------------------
# _filter()

## no critic (ProtectPrivateSubs)
is (Time::Duration::en_PIGLATIN::_filter('foo'),  'oofay');
is (Time::Duration::en_PIGLATIN::_filter('Foo'),  'Oofay');
is (Time::Duration::en_PIGLATIN::_filter('FOO'),  'OOFAY');
is (Time::Duration::en_PIGLATIN::_filter('food'), 'oodfay');
is (Time::Duration::en_PIGLATIN::_filter('I'),    'Iway');
is (Time::Duration::en_PIGLATIN::_filter('quay'), 'ayquay');
is (Time::Duration::en_PIGLATIN::_filter('qaar'), 'aarqay');


exit 0;
