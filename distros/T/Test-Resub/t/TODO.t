#!/usr/bin/env perl

use Test::More tests => 1;

ok( ! -e 'TODO',
  "You're not ready to release, you've still got a TODO" );
