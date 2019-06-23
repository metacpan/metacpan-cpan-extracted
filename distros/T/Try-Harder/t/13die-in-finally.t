#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Try::Harder;

# finally does not disturb $@
{
   local $SIG{__WARN__} = sub {};

   ok( !eval {
      try {
         die "oopsie";
      }
      finally {
         die "double oops";
      }
      1;
   }, 'die in both try{} and finally{} is still fatal' );
   like( $@, qr/^oopsie at /, 'die in finally{} does not corrupt $@' );
}

done_testing;
