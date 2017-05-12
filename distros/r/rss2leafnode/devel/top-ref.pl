#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Sort::Key::Top 'keytop';

sub myfunc {
}
my @bigarray;
for (my $i = 0; $i < 5000; $i++) {
  $bigarray[$i] = 123;
}
sub grow_the_stack {
  myfunc (@bigarray);
}

# PPCODE PUTBACK not reached
my @array = keytop {grow_the_stack(); $_} 3,   5,4,3,2,1;
print @array,"\n";
print @array,"\n";

# sub make_scalar {
#   my ($x) = @_;
#   return \$x;
# }
# 
# my $ref = make_scalar(123);
# print $ref,"\n";
# 
# my $r2;
# my @array = keytop { print "$_\n"; $r2 = \$_; $_ } 1, $$ref, $$ref;
# print $ref,"\n";
