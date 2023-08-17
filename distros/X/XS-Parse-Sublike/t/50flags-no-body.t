#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::flags";

BEGIN { $^H{"t::flags/no_body"} = 1 }

{
   no_body justaname;
   my $name; BEGIN { $name = $t::flags::captured_name; }
   is( $name, "justaname", 'no_body saw just the function name' );
}

done_testing;
