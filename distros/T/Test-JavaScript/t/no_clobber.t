#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::JavaScript;
js_ok('true', 'js ok');
js_ok(1, 'js ok');
ok(3 - 2, 'perl ok');
