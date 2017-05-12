#!perl

use strict;
use warnings;

use Test::More tests => 2 * 2 * 4;

my $n = 100;
my $i = 0;

{
 my $w;
 {
  my $r;
  no autovivification;
  $r = $w->[0][$i] for 1 .. $n;
 }
 is_deeply $w, undef, 'numerous fetches from an undef lexical';

 $w = [ undef ];
 {
  my $r;
  no autovivification;
  $r = $w->[0][$i] for 1 .. $n;
 }
 is_deeply $w, [ undef ], 'numerous fetches from a 1-level arrayref lexical';
}

{
 our $w;
 {
  my $r;
  no autovivification;
  $r = $w->[0][$i] for 1 .. $n;
 }
 is_deeply $w, undef, 'numerous fetches from an undef global';

 $w = [ undef ];
 {
  my $r;
  no autovivification;
  $r = $w->[0][$i] for 1 .. $n;
 }
 is_deeply $w, [ undef ], 'numerous fetches from a 1-level arrayref global';
}

{
 my $x;
 {
  my @r;
  no autovivification;
  @r = @{$x}[0, 1] for 1 .. $n;
 }
 is_deeply $x, undef, 'numerous slices from an undef lexical';

 $x = [ undef ];
 {
  my @r;
  no autovivification;
  @r = @{$x->[0]}[0, 1] for 1 .. $n;
 }
 is_deeply $x, [ undef ], 'numerous slices from a 1-level arrayref lexical';
}

{
 our $x;
 {
  my @r;
  no autovivification;
  @r = @{$x}[0, 1] for 1 .. $n;
 }
 is_deeply $x, undef, 'numerous slices from an undef global';

 $x = [ undef ];
 {
  my @r;
  no autovivification;
  @r = @{$x->[0]}[0, 1] for 1 .. $n;
 }
 is_deeply $x, [ undef ], 'numerous slices from a 1-level arrayref global';
}
{
 my $y;
 {
  my $r;
  no autovivification;
  $r = exists $y->[0][$i] for 1 .. $n;
 }
 is_deeply $y, undef, 'numerous exists from an undef lexical';

 $y = [ undef ];
 {
  my $r;
  no autovivification;
  $r = exists $y->[0][$i] for 1 .. $n;
 }
 is_deeply $y, [ undef ], 'numerous exists from a 1-level arrayref lexical';
}

{
 our $y;
 {
  my $r;
  no autovivification;
  $r = exists $y->[0][$i] for 1 .. $n;
 }
 is_deeply $y, undef, 'numerous exists from an undef global';

 $y = [ undef ];
 {
  my $r;
  no autovivification;
  $r = exists $y->[0][$i] for 1 .. $n;
 }
 is_deeply $y, [ undef ], 'numerous exists from a 1-level arrayref global';
}

{
 my $z;
 {
  my $r;
  no autovivification;
  $r = delete $z->[0][$i] for 1 .. $n;
 }
 is_deeply $z, undef, 'numerous deletes from an undef lexical';

 $z = [ undef ];
 {
  my $r;
  no autovivification;
  $r = delete $z->[0][$i] for 1 .. $n;
 }
 is_deeply $z, [ undef ], 'numerous deletes from a 1-level arrayref lexical';
}

{
 our $z;
 {
  my $r;
  no autovivification;
  $r = delete $z->[0][$i] for 1 .. $n;
 }
 is_deeply $z, undef, 'numerous deletes from an undef global';

 $z = [ undef ];
 {
  my $r;
  no autovivification;
  $r = delete $z->[0][$i] for 1 .. $n;
 }
 is_deeply $z, [ undef ], 'numerous deletes from a 1-level arrayref global';
}
