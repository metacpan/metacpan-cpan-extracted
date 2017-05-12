#!/usr/bin/perl -w

# Copyright 2011, 2012, 2015 Kevin Ryde

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

## no critic (RequireUseStrict, RequireUseWarnings)
use Test::Without::GD;

use 5.004;
use Test;
plan tests => 5;
ok (1, 1, 'Test::Without::GD load as first thing');


#------------------------------------------------------------------------------
# VERSION

my $want_version = 7;
ok ($Test::Without::GD::VERSION,
    $want_version,
    'VERSION variable');
ok (Test::Without::GD->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { Test::Without::GD->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Test::Without::GD->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# mode()

exit 0;
