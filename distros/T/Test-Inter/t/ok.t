#!/usr/bin/perl

use warnings 'all';
use strict;
BEGIN {
   if (-d "lib") {
      use lib "./lib";
   } elsif (-d "../lib") {
      use lib "../lib";
   }
}

use Test::Inter;
my $ti = new Test::Inter $0;

$ti->ok();
$ti->ok( 1 == 1 );
$ti->ok( 1 == 1,    "Basic test" );
$ti->ok( 1 == 1, 1, "Basic test" );
$ti->ok( 1 == 1, 2, "Basic test" );

sub func_false {
  return 0;
}
sub func_true {
  return 1;
}

sub func {
  my($a,$b) = @_;
  return $a == $b;
}

$ti->ok( \&func_true );
$ti->ok( \&func_true,    "True test" );
$ti->ok( \&func_true, 1, "True test" );
$ti->ok( \&func_true, 2, "True test" );

$ti->ok( \&func, [1,1]);
$ti->ok( \&func, [1,1],    "Func test" );
$ti->ok( \&func, [1,1], 1, "Func test" );
$ti->ok( \&func, [1,1], 2, "Func test" );

$ti->ok( [ 'a','b' ], [ 'a','b' ], "List test" );
$ti->ok( [ 'a','b' ], [ 'a','c' ], "List test (non-identical)" );

$ti->ok( { 'a' => 1, 'b' => 2 }, { 'a' => 1, 'b' => 2 }, "Hash test" );
$ti->ok( { 'a' => 1, 'b' => 2 }, { 'a' => 1, 'b' => 3 }, "Hash test (non-identical)" );

$ti->done_testing();

