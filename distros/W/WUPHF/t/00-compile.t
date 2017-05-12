#!perl

use strict;
use warnings;

use Test::More;
use WUPHF;

isa_ok(WUPHF->new, 'WUPHF');

done_testing();
