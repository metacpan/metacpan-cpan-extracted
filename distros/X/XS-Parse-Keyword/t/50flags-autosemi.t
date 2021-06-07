#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::flags";

BEGIN { $^H{"t::flags/permit"} = 1; }

{
   my $ret = do { flagautosemi semi; };
   is( $ret, "semi", 'result of flagautosemi followed by ";"' );
}

{
   my $ret = do { flagautosemi final };
   is( $ret, "final", 'result of flagautosemi followed by "}"' );
}

done_testing;
