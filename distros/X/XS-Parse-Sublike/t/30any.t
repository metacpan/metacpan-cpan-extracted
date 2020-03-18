#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib "t";
use testcase "t::any";

our $LOG; BEGIN { $LOG = "" };

prefixed func example {
   BEGIN { $LOG .= "B" }
}

is( $LOG, "EpEfBLfLpNpNf", 'stages run in correct order' );

done_testing;
