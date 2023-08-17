#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

{
   my $ret = piecevstring v1.23;
   isa_ok( $ret, "version" );
   is( $ret, "v1.23", 'result of piecevstring' );
}

{
   my $ret = piecevstring_opt v4.56;
   is( $ret, "v4.56", 'result of piecevstring_opt with version' );

   $ret = piecevstring_opt;
   ok( !defined $ret, 'result of piecevstring_opt without' );
}

done_testing;
