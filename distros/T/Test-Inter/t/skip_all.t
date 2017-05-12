#!/usr/bin/perl

use strict;
use warnings;
use Test::Inter;

my $o = new Test::Inter;

$o->skip_all("testing skip_all");
$o->plan(3);
$o->_ok("Test 1");
$o->diag("Test 1 diagnostic message");
$o->_ok("Test 2");
$o->_ok("Test 3");
