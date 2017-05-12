#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

my $test_count = (tests => 16)[1];
plan tests => $test_count;

use Regexp::Common 'no_defaults';
use App::MathImage::Regexp::Common::OEIS;

#------------------------------------------------------------------------------
# VERSION

my $want_version = 110;
ok ($App::MathImage::Regexp::Common::OEIS::VERSION, $want_version,
    'VERSION variable');
ok (App::MathImage::Regexp::Common::OEIS->VERSION, $want_version,
    'VERSION class method');

ok (eval { App::MathImage::Regexp::Common::OEIS->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { App::MathImage::Regexp::Common::OEIS->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");


#------------------------------------------------------------------------------
# "anum" regexp

foreach my $elem (['A',       0, undef ],
                  ['A123456', 1, '123456' ],
                  ['xxA1234567yy', 1, '1234567' ],
                 ) {
  my ($str, $want_match, $want_2) = @$elem;
  my $want_1 = $want_2 && ('A'.$want_2);

  {
    my $got_match = ($str =~ $RE{OEIS}{anum} ? 1 : 0);
    ok ($got_match, $want_match, "str=$str, no -keep");
  }
  {
    my $got_match = ($str =~ $RE{OEIS}{anum}{-keep} ? 1 : 0);
    my $got_1 = $1;
    my $got_2 = $2;

    ok ($got_match, $want_match, "str=$str, with -keep");
    ok ($got_1, $want_1, "str=$str, with -keep");
    ok ($got_2, $want_2, "str=$str, with -keep");
  }
}

#-----------------------------------------------------------------------------
exit 0;
