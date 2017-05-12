#!/usr/bin/perl

use strict;
use warnings;
use Test::Inter;

my $o = new Test::Inter;

$o->require_ok('5.001');
$o->require_ok('7.001','forbid');
$o->require_ok('Config');
$o->require_ok('Xxx::Yyy','forbid');
$o->require_ok('Symbol','feature');
$o->require_ok('Xxx::Zzz','feature');

$o->done_testing();

