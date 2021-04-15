#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::stages";

BEGIN { $^H{"t::stages/permitkey"} = 1; }
BEGIN { $^H{"t::stages/permitfunc"} = 1; }

our $VAR;

{
   BEGIN { $^H{"t::stages/check-capture"} = 1; }

   BEGIN { $VAR = "before" }

   no warnings 'void';
   stages {
      BEGIN { $VAR = "inside" }
   };

   is( $t::stages::captured, "before",
      'captured value of $VAR before block' );
}

done_testing;
