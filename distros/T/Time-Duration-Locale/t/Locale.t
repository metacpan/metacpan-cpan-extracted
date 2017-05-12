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
use Time::Duration::Locale;
use Test::More tests => 35;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $want_version = 12;
is ($Time::Duration::Locale::VERSION, $want_version,
    'VERSION variable');
is (Time::Duration::Locale->VERSION,  $want_version,
    'VERSION class method');
{ ok (eval { Time::Duration::Locale->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Time::Duration::Locale->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

# $ENV{'LANGUAGE'} = 'en';
# Time::Duration::Locale::setlocale();
# is (Time::Duration::Locale::module(), 'Time::Duration');


{
  my $can = Time::Duration::Locale->can('duration');
  ok ($can, 'can(duration) true');
  is ($can && ref $can, 'CODE', 'can(duration) is a coderef');
  cmp_ok (&$can(1), 'ne', '', ' can(duration) call');
}

{
  my $can = Time::Duration::Locale->can('language');
  ok ($can, 'can(language) true');
  is ($can && ref $can, 'CODE', 'can(language) is a coderef');
  is (&$can('en'), 'en', 'can(language) call');
}
{
  my $can = Time::Duration::Locale->can('nosuchfunctionnameexists');
  is ($can, undef, 'can(nosuchfunctionnameexists) undef');
}

cmp_ok (duration(1), 'ne', '',
        'duration(1)');
cmp_ok (duration(1,1), 'ne', '',
        'duration(1,1)');
cmp_ok (duration_exact(1), 'ne', '',
        'duration(1)');

cmp_ok (ago(1), 'ne', '',
        'ago(1)');
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
  my $ret = eval { Time::Duration::Locale::testnosuchfunction(); 1 };
  my $error = $@;
  ok (! $ret, 'testnosuchfunction() fails');
  like ($error, '/No such function/', 'testnosuchfunction() error message');
}

#------------------------------------------------------------------------------
# module() setting

foreach my $module ('Time::Duration::Locale', 'Time::Duration::LocaleObject') {
  ok (eval "require $module", "load $module");
  my $got = eval { Time::Duration::Locale::module($module); 1 };
  my $err = $@;
  ok (! $got, "module() refuse to set recursive $module");
  like ($err, '/Locale or LocaleObject/',
        "module() error message for $module");
}


exit 0;
