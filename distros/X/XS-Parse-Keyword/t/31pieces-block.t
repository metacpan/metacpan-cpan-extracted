#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

{
   my $ret = pieceblock { "block value" };
   is( $ret, "(block value)", 'result of pieceblock' );
}

{
   my @ret;
   # scalar reverse will join() strings
   @ret = pieceblock_scalar { reverse "abc", "def" };
   is( \@ret, [ "fedcba" ], 'pieceblock_scalar forces scalar context' );

   @ret = pieceblock_list { reverse "abc", "def" };
   is( \@ret, [ "def,abc" ], 'pieceblock_list forces list context' );
}

{
   my $ret = pieceprefixedblock $scalar = 123, { $scalar + 456 };
   is( $ret, 123+456, 'result of pieceprefixedblock' );
}

{
   my $ret = pieceprefixedblock_VAR { "$VAR, world!" };
   is( $ret, "(Hello, world!)", 'result of pieceprefixedblock_VAR' );
}

done_testing;
