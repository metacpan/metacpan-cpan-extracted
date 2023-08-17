#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

{
   my $ret = piececolon : ;
   is( $ret, "colon", 'result of piececolon' );
}

{
   my $ret = piecestr foo ;
   is( $ret, "foo", 'result of piecestr' );
}

{
   my $ret = piecekw bar ;
   is( $ret, "bar", 'result of piecekw' );
}

{
   my $ret1 = do { pieceautosemi; };
   is( $ret1, "EOS", 'result of pieceautosemi with ;' );

   my $ret2 = do { pieceautosemi };
   is( $ret2, "EOS", 'result of pieceautosemi at end of block' );
}

done_testing;
