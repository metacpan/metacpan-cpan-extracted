#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use feature 'signatures';
no warnings 'experimental';

use lib "t";
use testcase "t::func";

BEGIN { $^H{"t::func/afunc"}++ }
BEGIN { $^H{"t::func/Attribute"}++ }

our @ATTRIBUTE_APPLIED;

{
   afunc withattr($x :Attribute, $y :Attribute(Value)) { }

   is( \@ATTRIBUTE_APPLIED,
      [ '$x' => undef, '$y' => "Value" ],
      ':Attribute applied to subroutine parameters' );
}

done_testing;
