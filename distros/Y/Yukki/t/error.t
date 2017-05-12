#!/usr/bin/env perl
use 5.12.1;

use Test::More tests => 2;

use_ok('Yukki::Error');
can_ok('Yukki::Error', 'throw');
