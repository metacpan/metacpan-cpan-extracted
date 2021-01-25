#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::parts";

# name optional
{
   parts NAME { }

   my $code = parts { };
   is( ref $code, "CODE", '$code is CODEref' );
}

# name required
{
   BEGIN { $^H{"t::parts/require-name"} = 1; }

   ok( !defined eval 'my $code = parts { };',
      'anon func fails to parse when name required' );
}

# name skipped
{
   BEGIN { $^H{"t::parts/skip-name"} = 1; }

   ok( !defined eval 'parts OTHERNAME { }; 1',
      'named func fails to parse when name skipped' );
}

done_testing;
