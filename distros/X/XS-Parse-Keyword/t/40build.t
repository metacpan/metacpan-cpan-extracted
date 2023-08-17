#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::build";

BEGIN { $^H{"t::build/permit"} = 1; }

{
   my $ret;
   $ret = build { "block here" } "value here";
   is( $ret, "block here|value here", 'result of build' );
}

done_testing;
