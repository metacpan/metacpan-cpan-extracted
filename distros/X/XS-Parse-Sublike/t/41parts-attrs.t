#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::parts";

# attrs optional
{
   parts NAME { }

   parts ANAME :method { }

   pass( 'Optional attributes permitted but not required' );
}

# attrs skipped
{
   BEGIN { $^H{"t::parts/skip-attrs"} = 1; }

   ok( !defined eval 'parts OTHERNAME :method { }; 1',
      'func with attrs to parse when attrs skipped' );
}

done_testing;
