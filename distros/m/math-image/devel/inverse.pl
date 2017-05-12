#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
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
use warnings;
use Math::BigRat;

use Smart::Comments;


my_inverse (4, 4, 59);

sub my_inverse {
  my ($a, $b, $c) = @_;

  $a = Math::BigRat->new($a);
  $b = Math::BigRat->new($b);
  $c = Math::BigRat->new($c);

  my $evaluate = sub {
    my ($x) = @_;
    return ($a*$x*$x + $b*$x + $c);
  };
  foreach my $i (0 .. 10) {
    print $evaluate->($i),", ";
  }
  print "\n";

  my $x = -$b/(2*$a);
  my $y = 4*$a / ((2*$a) ** 2);
  my $z = ($b*$b-4*$a*$c) / ((2*$a) ** 2);
  print "s = $x + sqrt($y * \$n + $z)\n";

  #   return;

  my $s_to_n = sub {
    my ($s) = @_;
    return $evaluate->($s);
  };

  $x = $x->numify;
  $y = $y->numify;
  $z = $z->numify;
  my $n_to_s = sub {
    my ($n) = @_;
    my $root = $y * $n + $z;
    if ($root < 0) {
      return 'neg sqrt';
    }
    return ($x + sqrt($root));
  };
  for (my $i = 0; $i < 100; $i += 0.5) {
    printf "%4s  d=%s\n", $i, $n_to_s->($i);
  }
  exit 0;
}

