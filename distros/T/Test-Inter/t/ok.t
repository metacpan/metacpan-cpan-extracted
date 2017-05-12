#!/usr/bin/perl

use Test::Inter;
$o = new Test::Inter;

$o->ok();
$o->ok( 1 == 1 );
$o->ok( 1 == 1,    "Basic test" );
$o->ok( 1 == 1, 1, "Basic test" );
$o->ok( 1 == 1, 2, "Basic test" );

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

$o->ok( \&func_true );
$o->ok( \&func_true,    "True test" );
$o->ok( \&func_true, 1, "True test" );
$o->ok( \&func_true, 2, "True test" );

$o->ok( \&func, [1,1]);
$o->ok( \&func, [1,1],    "Func test" );
$o->ok( \&func, [1,1], 1, "Func test" );
$o->ok( \&func, [1,1], 2, "Func test" );

$o->ok( [ 'a','b' ], [ 'a','b' ], "List test" );
$o->ok( [ 'a','b' ], [ 'a','c' ], "List test (non-identical)" );

$o->ok( { 'a' => 1, 'b' => 2 }, { 'a' => 1, 'b' => 2 }, "Hash test" );
$o->ok( { 'a' => 1, 'b' => 2 }, { 'a' => 1, 'b' => 3 }, "Hash test (non-identical)" );

$o->done_testing();

