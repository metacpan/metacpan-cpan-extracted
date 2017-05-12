#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

{
  sub make_subr {
    return sub { 123 };
  }

  my $x = make_subr();
  require Scalar::Util;
  require Data::Dumper;
  Scalar::Util::weaken($x);
  print Data::Dumper->Dump([\$x],['x']);

  # require Devel::FindRef;
  # print Devel::FindRef::track(\$x);

  no warnings 'redefine';
  *make_subr = sub {};
  print Data::Dumper->Dump([\$x],['x']);

  sub make_two {
    my ($a) = @_;
    return sub { $a };
  }

  $x = make_two(123);
  my $y = make_two(456);
  Scalar::Util::weaken($x);
  #Scalar::Util::weaken($y);
  print Data::Dumper->Dump([\$x],['x']);
  print Data::Dumper->Dump([\$y],['y']);
  exit 0;
}

{
  use constant::defer my_ctime => sub { return 123;
                                        #require POSIX;
                                        #return POSIX::ctime(time());
                                      };
  my $orig = \&my_ctime;
  print my_ctime(),"\n";
  my $const = \&my_ctime;

  print "orig  $orig\n";
  print "const $const\n";
  print "subr  ",$constant::defer::DEBUG_LAST_SUBR,"\n";
  require Scalar::Util;
  Scalar::Util::weaken($constant::defer::DEBUG_LAST_SUBR);
  print "subr  ",$constant::defer::DEBUG_LAST_SUBR,"\n";
  exit 0;
}
