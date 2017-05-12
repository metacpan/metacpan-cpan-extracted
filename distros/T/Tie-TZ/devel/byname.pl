#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use POSIX ('tzset');

sub foo {
  print "foo\n";
}
sub bar {
  print "bar\n";
}
sub other {
  print "other\n";
}
sub call {
  foo ();
}
call();
*foo = *bar;
call();
*foo = sub { print "quux\n"; };
call();
*foo = *other;
call();
bar();

print "imported tzset ",\&tzset,"\n";
print "POSIX::tzset   ",\&POSIX::tzset,"\n";
{ no warnings 'redefine';
  *POSIX::tzset = sub { print "new tzset\n"; };
}
print "imported tzset ",\&tzset,"\n";
print "POSIX::tzset   ",\&POSIX::tzset,"\n";
exit 0;
