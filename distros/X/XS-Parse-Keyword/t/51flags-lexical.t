#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.016000 or plan skip_all => "Lexical-prefixed keywords are not supported on Perl 5.14";
}

use lib "t";
use testcase "t::flags";

BEGIN { $^H{"t::flags/permit"} = 1; }

{
   my $ret = do { my flaglex lexical; };
   is( $ret, "my lexical" );
}

{
   my $ret = do { flaglex nonlexical; };
   is( $ret, "nonlexical" );
}

done_testing;
