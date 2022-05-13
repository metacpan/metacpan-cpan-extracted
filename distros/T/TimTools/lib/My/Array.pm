#!/usr/bin/env perl

package My::Array;

use v5.32;
use Mojo::Base -strict;
use List::Util qw( max );

sub max_lengths {
   my ( $s, $rows ) = @_;
   my $last_row    = $rows->$#*;
   my $last_column = $rows->[0]->$#*;

   my @max = map {
      my $col = $_;
      max map { length $rows->[$_][$col]; } 0 .. $last_row;
   } 0 .. $last_column;

   \@max;
}

1;
