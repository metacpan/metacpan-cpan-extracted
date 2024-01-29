#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use meta;

my $FILE = quotemeta __FILE__;

{
   my $LINE = __LINE__+1;
   like( warning { meta::get_package( "meta" ) },
      qr/^meta::get_package is experimental and may be changed or removed without notice at $FILE line $LINE\./,
      'meta::get_package provokes experimental warning' );
}

{
   no warnings 'meta::experimental';

   is( warning { meta::get_package( "meta" ) },
      undef,
      'experimental warnings can be disabled' );
}

done_testing;
