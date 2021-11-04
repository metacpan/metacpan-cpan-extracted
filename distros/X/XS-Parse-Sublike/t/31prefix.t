#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use lib "t";
use testcase "t::prefix";

our $LOG; BEGIN { $LOG = "" };

prefixed func example {
   BEGIN { $LOG .= "B" }
}

is( $LOG, "SpSfEpEfBLfLpNpNf", 'stages run in correct order' );

done_testing;
