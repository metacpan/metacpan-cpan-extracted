#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

# This file is part of constant-defer.
#
# constant-defer is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# constant-defer is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with constant-defer.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Memoize::ToConstant;
use Test::More tests => 22;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 1;
ok ($Memoize::ToConstant::VERSION >= $want_version,
    'VERSION variable');
ok (Memoize::ToConstant->VERSION  >= $want_version,
    'VERSION class method');
Memoize::ToConstant->VERSION ($want_version);


# basic use
{
  my $foo_runs = 0;
  sub foo { $foo_runs = 1; return 123 }

  my $orig_code;
  BEGIN { $orig_code = \&foo; }

  use Memoize::ToConstant 'foo';

  is (foo(), 123, 'foo() first run');
  is ($foo_runs, 1, 'foo() first runs code');

  require Scalar::Util;
  Scalar::Util::weaken ($orig_code);
  is ($orig_code, undef, 'orig foo() code garbage collected');

  $foo_runs = 0;
  is (foo(), 123, 'foo() second run');
  is ($foo_runs, 0, 'foo() second doesn\'t run code');
}

{
  my $succeeds = (eval { Memoize::ToConstant->import('nosuchfunc') }
                  ? 1 : 0);
  is ($succeeds, 0, 'no such func provokes die');
}

{
  my $succeeds = 0;
  BEGIN {
    ##no critic (BuiltinFunctions::ProhibitStringyEval)
    if (eval "use Memoize::ToConstant 'before'; 1") {
      $succeeds = 1;
    }
  }
  sub before { return 789 }

  is ($succeeds, 0, 'memoize before defined provokes die');
}

{
  my $runs = 0;
  sub Some::Non::Package::Place::func { $runs = 1; return 'xyz' }
  use Memoize::ToConstant 'Some::Non::Package::Place::func';

  is (Some::Non::Package::Place::func(), 'xyz',
      'explicit package first run');
  is ($runs, 1,
      'explicit package first run runs code');

  $runs = 0;
  is (Some::Non::Package::Place::func(), 'xyz',
      'explicit package second run');
  is ($runs, 0,
      'explicit package second run doesn\'t run code');
}

{
  my $runs = 0;
  sub three { $runs = 1;
              return ('a','b','c') }
  use Memoize::ToConstant 'three';

  is_deeply ([ three() ], [ 'a', 'b', 'c' ],
             'three return values first run');
  is ($runs, 1,
      'three return values first run runs code');

  $runs = 0;
  is_deeply ([ three() ], [ 'a', 'b', 'c' ],
             'three return values second run');
  is ($runs, 0,
      'three return values second run doesn\'t run code');
}

{
  my $runs = 0;
  sub three_scalar { $runs = 1;
                     return ('a','b','c') }
  use Memoize::ToConstant 'three_scalar';

  my $got = three_scalar();
  is ($got, 3,
      'three values in scalar context return values first run');
  is ($runs, 1,
      'three values in scalar context return values first run runs code');

  $runs = 0;
  $got = three_scalar();
  is ($got, 3,
      'three values in scalar context return values second run');
  is ($runs, 0,
      'three values in scalar context return values second run doesn\'t run code');
}

exit 0;

