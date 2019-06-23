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
   catch {
      $s = 2;
   }

   is( $s, 1, 'sucessful try{} runs' );
}

# try catches
{
   my $s;
   ok( eval {
      try {
         die "oopsie";
      }
      catch { }

      $s = 3;
      "ok";
   }, 'try { die } is not fatal' );

   is( $s, 3, 'code after try{} runs' );
}

# exceptions that are false
{
   my $caught;
   try {
      die FALSE->new;
   }
   catch {
      $caught++;
   }

   ok( $caught, 'catch{} sees a false exception' );

   {
      package FALSE;
      use overload 'bool' => sub { 0 };
      sub new { bless [], shift }
   }
}

# catch sees $@
{
   my $e;
   try {
      die "oopsie";
   }
   catch {
      $e = $@;
   }

   like( $e, qr/^oopsie at /, 'catch{} sees $@' );
}

# catch block executes
{
   my $s;
   try {
      die "oopsie";
   }
   catch {
      $s = 4;
   }

   is( $s, 4, 'catch{} of failed try{} runs' );
}

# catch can rethrow
{
   my $caught;
   ok( !eval {
      try { die "oopsie"; }
      catch { $caught = $@; die $@ }
   }, 'die in catch{} is fatal' );
   my $e = $@;

   like( $e, qr/^oopsie at /, 'exception is thrown' );
   like( $caught, qr/^oopsie at /, 'exception was seen by catch{}' );
}

done_testing;
