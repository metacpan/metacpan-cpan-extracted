#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Try::Harder;

# die in catch is fatal
{
   ok( !eval {
      try { die "oopsie"; }
      catch { die $@ }
   }, 'die in catch{} is fatal' );
}


# catch can rethrow
{
   my $caught;
   eval {
      try { die "oopsie"; }
      catch { $caught = $@; die $@ }
   };
   my $e = $@;

   like( $e, qr/^oopsie at /, 'exception is thrown' );
   like( $caught, qr/^oopsie at /, 'exception was seen by catch{}' );
}

done_testing;
