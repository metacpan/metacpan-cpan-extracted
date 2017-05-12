#!/usr/bin/perl

use strict;
use warnings;

our($o);

BEGIN {
  use Test::Inter;
  $o = new Test::Inter;
}

BEGIN { $o->use_ok('5.004'); }
BEGIN { $o->use_ok('Config'); }
BEGIN { $o->use_ok('Xxx::Yyy','forbid'); }
BEGIN { $o->use_ok('Symbol','feature'); }
BEGIN { $o->use_ok('Xxx::Zzz','feature'); }
BEGIN { $o->use_ok('Storable',1.01); }

$o->done_testing();

