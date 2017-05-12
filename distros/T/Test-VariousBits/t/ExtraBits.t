#!/usr/bin/perl

# Copyright 2009, 2011 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 16;
use Test::Weaken::ExtraBits;

sub foo {
}
sub bar {
}
{
  package MyModule1;
  sub quux {}
}

#-----------------------------------------------------------------------------
# ignore_global_functions()

ok (! Test::Weaken::ExtraBits::ignore_global_functions(\(123)),
    1,
    'ignore_global_functions scalar ref');
ok (! Test::Weaken::ExtraBits::ignore_global_functions([]),
    1,
    'ignore_global_functions array ref');
ok (! Test::Weaken::ExtraBits::ignore_global_functions({}),
    1,
    'ignore_global_functions hash ref');
ok (! Test::Weaken::ExtraBits::ignore_global_functions(sub {}),
    1,
    'ignore_global_functions anon coderef');

ok (Test::Weaken::ExtraBits::ignore_global_functions(\&foo),
    1,
    'ignore_global_functions foo() coderef');
ok (Test::Weaken::ExtraBits::ignore_global_functions(\&MyModule1::quux),
    1,
    'ignore_global_functions MyModule1::quux() coderef');

ok (! Test::Weaken::ExtraBits::ignore_global_functions(\&No::Such::Module::foo),
    1,
    'ignore_global_functions No::Such::Module::foo coderef');

#-----------------------------------------------------------------------------
# ignore_functions()

ok (! Test::Weaken::ExtraBits::ignore_functions(\(123), 'main::foo'),
    1,
    'ignore_functions scalar ref');
ok (! Test::Weaken::ExtraBits::ignore_functions([], 'main::foo'),
    1,
    'ignore_functions array ref');
ok (! Test::Weaken::ExtraBits::ignore_functions({}, 'main::foo'),
    1,
    'ignore_functions hash ref');
ok (! Test::Weaken::ExtraBits::ignore_functions(sub {}, 'main::foo'),
    1,
    'ignore_functions anon coderef');

ok (Test::Weaken::ExtraBits::ignore_functions(\&foo, 'main::foo'),
    1,
    'ignore_functions foo() coderef');
ok (Test::Weaken::ExtraBits::ignore_functions(\&MyModule1::quux,
                                              'MyModule1::quux'),
    1,
    'ignore_functions MyModule1::quux() coderef');
ok (Test::Weaken::ExtraBits::ignore_functions(\&foo, 'main::foo', 'main::bar'),
    1,
    'ignore_functions foo() coderef, two');
ok (Test::Weaken::ExtraBits::ignore_functions(\&bar, 'main::foo', 'main::bar'),
    1,
    'ignore_functions bar() coderef, two');

ok (! Test::Weaken::ExtraBits::ignore_functions(\&No::Such::Module::foo,
                                                'main::foo', 'main::bar'),
    1,
    'ignore_functions No::Such::Module::foo coderef');

#-----------------------------------------------------------------------------
# ignore_module_functions()

# ok (! Test::Weaken::ExtraBits::ignore_module_functions(\(123), 'main'),
#     1,
#     'ignore_module_functions scalar ref');
# ok (! Test::Weaken::ExtraBits::ignore_module_functions([], 'main'),
#     1,
#     'ignore_module_functions array ref');
# ok (! Test::Weaken::ExtraBits::ignore_module_functions({}, 'main'),
#     1,
#     'ignore_module_functions hash ref');
# ok (! Test::Weaken::ExtraBits::ignore_module_functions(sub {}, 'main'),
#     1,
#     'ignore_module_functions anon coderef');
#
# ok (Test::Weaken::ExtraBits::ignore_module_functions(\&foo, 'main'),
#     1,
#     'ignore_module_functions foo() coderef');
# ok (! Test::Weaken::ExtraBits::ignore_module_functions(\&foo, 'MyModule1'),
#     1,
#     'ignore_module_functions foo() not in MyModule1');
#
# ok (! Test::Weaken::ExtraBits::ignore_module_functions(\&foo,
#                                                        'NoSuchModuleName'),
#     1,
#     'ignore_module_functions foo() no NoSuchModuleName');
# ok (! %NoSuchModuleName::,
#     1,
#     "ignore_module_functions doesn't create NoSuchModuleName");
#
# ok (Test::Weaken::ExtraBits::ignore_module_functions(\&foo,
#                                                      'main', 'MyModule1'),
#     1,
#     'ignore_module_functions foo() coderef, two');
# ok (Test::Weaken::ExtraBits::ignore_module_functions(\&MyModule1::quux,
#                                                      'main', 'MyModule1'),
#     1,
#     'ignore_module_functions quux() coderef, two');
#
# ok (! Test::Weaken::ExtraBits::ignore_module_functions(\&No::Such::Module::foo,
#                                                        'main', 'MyModule1'),
#     1,
#     'ignore_module_functions No::Such::Module::foo coderef');

exit 0;
