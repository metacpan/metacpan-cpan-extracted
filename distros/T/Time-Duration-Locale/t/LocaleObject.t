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

use 5.004;
use strict;
use Time::Duration::LocaleObject;
use Test::More tests => 24;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $want_version = 12;
is ($Time::Duration::LocaleObject::VERSION, $want_version,
    'VERSION variable');
is (Time::Duration::LocaleObject->VERSION,  $want_version,
    'VERSION class method');
{ ok (eval { Time::Duration::LocaleObject->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Time::Duration::LocaleObject->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}
{ my $tdl = Time::Duration::LocaleObject->new;
  is ($tdl->VERSION, $want_version, 'VERSION object method');
  ok (eval { $tdl->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $tdl->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# class

cmp_ok (Time::Duration::LocaleObject->duration(1), 'ne', '',
        'Time::Duration::LocaleObject->duration(1)');

#------------------------------------------------------------------------------
# instance

{
  my $tdl = Time::Duration::LocaleObject->new;
  is ($tdl->module,   undef, 'module() initially undef');
  is ($tdl->language, undef, 'language() initially undef');

  cmp_ok ($tdl->duration(1), 'ne', '', 'tdlobj->duration(1)');

  isnt ($tdl->module,   undef, 'module() resolved to non-undef');
  isnt ($tdl->language, undef, 'language() resolved to non-undef');

  {
    my $coderef = Time::Duration::LocaleObject->can('duration');
    cmp_ok ($tdl->$coderef(1), 'ne', '', 'tdlobj->durationcoderef(1)');
  }
  {
    my $can = Time::Duration::LocaleObject->can('nosuchfunctionnameexists');
    is ($can, undef, 'can(nosuchfunctionnameexists) undef');
  }

  {
    my $ret = eval {
      $tdl->module('Time::Duration::LocaleObject::TestWhenNoSuchModule');
      1 };
    ok (! $ret, 'TestWhenNoSuchModule eval fails');
    cmp_ok ($tdl->duration(1), 'ne', '',
            'duration() still ok after TestWhenNoSuchModule');
  }
}

foreach my $norecurse_module ('Time::Duration::Locale',
                              'Time::Duration::LocaleObject') {
  use_ok ($norecurse_module);
  my $got = eval { Time::Duration::LocaleObject->new (module => $norecurse_module); 1 };
  my $err = $@;
  ok (! $got, "refuse recursive module $norecurse_module");
  like ($err, '/Locale or LocaleObject/',
        "error message for $norecurse_module");
}


#------------------------------------------------------------------------------
# language()

{
  my $tdl = Time::Duration::LocaleObject->new;
  is ($tdl->language('en'), 'en', 'set language(en)');
}

exit 0;
