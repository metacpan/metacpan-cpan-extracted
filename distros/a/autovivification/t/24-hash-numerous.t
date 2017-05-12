#!perl

use strict;
use warnings;

use Test::More tests => 2 * 2 * 4;

my $n = 100;

{
 my $w;
 {
  my $r;
  no autovivification;
  $r = $w->{a}{b} for 1 .. $n;
 }
 is_deeply $w, undef, 'numerous fetches from an undef lexical';

 $w = { a => undef };
 {
  my $r;
  no autovivification;
  $r = $w->{a}{b} for 1 .. $n;
 }
 is_deeply $w, { a => undef },'numerous fetches from a 1-level hashref lexical';
}

{
 our $w;
 {
  my $r;
  no autovivification;
  $r = $w->{a}{b} for 1 .. $n;
 }
 is_deeply $w, undef, 'numerous fetches from an undef global';

 $w = { a => undef };
 {
  my $r;
  no autovivification;
  $r = $w->{a}{b} for 1 .. $n;
 }
 is_deeply $w, { a => undef },'numerous fetches from a 1-level hashref global';
}

{
 my $x;
 {
  my @r;
  no autovivification;
  @r = @{$x}{qw<a b>} for 1 .. $n;
 }
 is_deeply $x, undef, 'numerous slices from an undef lexical';

 $x = { a => undef };
 {
  my @r;
  no autovivification;
  @r = @{$x->{a}}{qw<b c>} for 1 .. $n;
 }
 is_deeply $x, { a => undef }, 'numerous slices from a 1-level hashref lexical';
}

{
 our $x;
 {
  my @r;
  no autovivification;
  @r = @{$x}{qw<a b>} for 1 .. $n;
 }
 is_deeply $x, undef, 'numerous slices from an undef global';

 $x = { a => undef };
 {
  my @r;
  no autovivification;
  @r = @{$x->{a}}{qw<b c>} for 1 .. $n;
 }
 is_deeply $x, { a => undef }, 'numerous slices from a 1-level hashref global';
}

{
 my $y;
 {
  my $r;
  no autovivification;
  $r = exists $y->{a}{b} for 1 .. $n;
 }
 is_deeply $y, undef, 'numerous exists from an undef lexical';

 $y = { a => undef };
 {
  my $r;
  no autovivification;
  $r = exists $y->{a}{b} for 1 .. $n;
 }
 is_deeply $y, { a => undef },'numerous exists from a 1-level hashref lexical';
}

{
 our $y;
 {
  my $r;
  no autovivification;
  $r = exists $y->{a}{b} for 1 .. $n;
 }
 is_deeply $y, undef, 'numerous exists from an undef global';

 $y = { a => undef };
 {
  my $r;
  no autovivification;
  $r = exists $y->{a}{b} for 1 .. $n;
 }
 is_deeply $y, { a => undef },'numerous exists from a 1-level hashref global';
}

{
 my $z;
 {
  my $r;
  no autovivification;
  $r = delete $z->{a}{b} for 1 .. $n;
 }
 is_deeply $z, undef, 'numerous deletes from an undef lexical';

 $z = { a => undef };
 {
  my $r;
  no autovivification;
  $r = delete $z->{a}{b} for 1 .. $n;
 }
 is_deeply $z, { a => undef },'numerous deletes from a 1-level hashref lexical';
}

{
 our $z;
 {
  my $r;
  no autovivification;
  $r = delete $z->{a}{b} for 1 .. $n;
 }
 is_deeply $z, undef, 'numerous deletes from an undef global';

 $z = { a => undef };
 {
  my $r;
  no autovivification;
  $r = delete $z->{a}{b} for 1 .. $n;
 }
 is_deeply $z, { a => undef },'numerous deletes from a 1-level hashref global';
}
