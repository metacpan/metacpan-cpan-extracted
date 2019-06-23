#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Try::Harder;

# try success
{
   my $s;
   try {
      $s = 1;
   }
   finally {
      $s = 2;
   }

   is( $s, 2, 'sucessful try{} runs finally{}' );
}

# try failure
{
   my $s;
   my $e;
   ok( !eval {
      try {
         die "oopsie";
      }
      finally {
         $e = $@;
         $s = 3;
      }
   }, 'failed try{} throws' );
   my $dollarat = $@;

   is( $s, 3, 'failed try{} runs finally{}' );
   like( $e, qr/^oopsie at /, 'finally{} sees $@' );
   like( $dollarat, qr/^oopsie at /, 'try/finally leaves $@ intact' );
}

# finally runs on 'return'
{
   my $final;
   ( sub {
      try {
         return;
      }
      finally {
         $final++;
      }
   } )->();

   ok( $final, 'finally{} runs after return' );
}

# finally runs on 'goto'
{
   my $final;
   try {
      goto after;
   }
   finally {
      $final++;
   }

after:
   ok( $final, 'finally{} runs after goto' );
}

# finally runs on 'last'
{
   my $final;
   LOOP: {
      try {
         last LOOP;
      }
      finally {
         $final++;
      }
   }

   ok( $final, 'finally{} runs after last' );
}

done_testing;
