#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use feature 'signatures';
no warnings 'experimental';

use lib "t";
use testcase "t::parts";

# signature optional
{
   parts NAME { }

   parts ANAME ($x) { }

   pass( 'Optional attributes permitted but not required' );
}

# signature skipped
{
   BEGIN { $^H{"t::parts/skip-signature"} = 1; }

   ok( !defined eval 'parts OTHERNAME ($x) { }; 1',
      'func with signature to parse when signature skipped' );
}

done_testing;
