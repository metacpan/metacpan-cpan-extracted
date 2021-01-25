#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::stages";

our $VAR;
BEGIN { $^H{"t::stages/permit"} = 1; }

{
   BEGIN { $^H{'t::stages/filter_attr-capture'} = 1; }

   stages withattr :atname(atvalue) { }

   is_deeply( $t::stages::captured, [ atname => "atvalue" ],
      'captured an attribute by attr filter' );
}

done_testing;
