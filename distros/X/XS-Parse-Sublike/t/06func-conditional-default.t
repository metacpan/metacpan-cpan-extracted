#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
   $] >= 5.038000 or plan skip_all => "No OPpARG_IF_UNDEF";
}

use feature 'signatures';
no warnings 'experimental';

use lib "t";
use testcase "t::func";

BEGIN { $^H{"t::func/nfunc"}++ }

# defaulting expressions can use //= and ||=
{
   nfunc withdefined($x //= "default") { return $x }

   is( withdefined( "value" ), "value",   'param with defined-or' );
   is( withdefined( undef ),   "default", 'param with defined-or defaulting' );

   nfunc withtrue($x ||= "default") { return $x }

   is( withtrue( "value" ), "value",   'param with true-or' );
   is( withtrue( "" ),      "default", 'param with true-or defaulting' );
}

done_testing;
