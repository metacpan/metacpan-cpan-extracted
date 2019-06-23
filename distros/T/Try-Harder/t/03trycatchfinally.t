#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Try::Harder;

# try success
{
   my $s;
   try {
      $s = 1;  # overwritten
   }
   catch {
      die "FAIL";
   }
   finally {
      $s = 2;
   }

   is( $s, 2, 't/c/f runs finally' );
}

# try failure
{
   my $s;
   try {
      die "oopsie";
   }
   catch {
      $s = 3;
   }
   finally {
      $s++;
   }

   is( $s, 4, 't/c/f runs catch{} and finally{} on failure' );
}

done_testing;
