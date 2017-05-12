#!/usr/bin/perl

use Test::Inter;
$o = new Test::Inter;

$o->is  ( [ 'a','b' ], [ 'a','b' ], "List test" );
$o->isnt( [ 'a','b' ], [ 'a','c' ], "List test" );

$o->is  ( { 'a' => 1, 'b' => 2 }, { 'a' => 1, 'b' => 2 }, "Hash test" );
$o->isnt( { 'a' => 1, 'b' => 2 }, { 'a' => 1, 'b' => 3 }, "Hash test" );

$o->done_testing();

