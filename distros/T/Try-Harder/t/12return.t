#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Try::Harder;

# return from try
{
   my $after;

   is(
      ( sub {
         try { return "result" }
         catch {}
         $after++;
         return "nope";
      } )->(),
      "result",
      'return in try leaves containing function'
   );
   ok( !$after, 'code after try{return} is not invoked' );
}

# return from two nested try{}s
{
   my $after;

   is(
      ( sub {
         try {
            try { return "result" }
            catch {}
         }
         catch {}
         $after++;
         return "nope";
      } )->(),
      "result",
      'return in try{try{}} leaves containing function'
   );
   ok( !$after, 'code after try{try{return}} is not invoked' );
}

# return inside eval{} inside try{}
{
   is(
      ( sub {
         my $two;
         try {
            my $one = eval { return 1 };
            $two = $one + 1;
         }
         catch {}
         return $two;
      } )->(),
      2,
      'return in eval{} inside try{} behaves as expected'
   );
}

# return from catch
{
   is(
      ( sub {
         try { die "oopsie" }
         catch { return "result" }
         return "nope";
      } )->(),
      "result",
      'return in catch leaves containing function'
   );
}

done_testing;
