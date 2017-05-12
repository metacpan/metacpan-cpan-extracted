#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use_ok( 'Test::Ping');

create_ping_object_not_ok('xxx', "failed ok");

done_testing();

