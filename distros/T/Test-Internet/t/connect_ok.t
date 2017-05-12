#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use Test::More;
use Test::Internet;

plan skip_all => "No internet connection." unless connect_ok();

ok(connect_ok());

done_testing();
