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

use 5.010;
use strict;
use warnings;
use B;
use B::Utils;
use Devel::Peek;
use Data::Dumper;

use constant::defer FOO => sub { 123 };
Dump (\&FOO);

my $c = B::svref_2object(\&FOO);
say $c;

my $op = $c->ROOT;
say "op $op";
B::Utils::walkoptree_simple($op, sub {
                              my ($op) = @_;
                              say "walk $op ",$op->name," ",$op->targ;
                            });


__END__
# B::walkoptree($op, 'main::myop');
# sub myop {
#   my ($op) = @_;
#   say "myop ",$op;
# }


exit 0;

my $pad = $c->PADLIST;
say "pad ",$pad," fill ",$pad->FILL," max ",$pad->MAX;

{
  my $ref = $pad->object_2svref;
  say "pad ",Dumper(\$ref);
}
my @pa = $pad->ARRAY;
say "pa ",@pa; # $a," fill ",$a->FILL," max ",$a->MAX;

foreach my $a (@pa) {
  say "a ",$a;
  my @aa = $pad->ARRAY;
  say " aa ",@aa; # $a," fill ",$a->FILL," max ",$a->MAX;
  foreach my $b (@aa) {
    say "  ",$b;
    my $ref = $b->object_2svref;
    say "  ",Dumper(\$ref);

    my @bb = $b->ARRAY;
    say "    bb ",@bb;<
  }
}

exit 0;

