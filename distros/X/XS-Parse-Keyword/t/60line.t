#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::line";

BEGIN { $^H{"t::line/permit"} = 1; }

{
   my $ret = line here;
   is( $ret, __LINE__-1, 'line captures line number' );
}

done_testing;
