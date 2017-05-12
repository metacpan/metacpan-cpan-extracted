#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 2 };

BEGIN { use_ok 'Test::Environment' }

is($ENV{'RUNNING_ENVIRONMENT'}, 'testing', 'check RUNNING_ENVIRONMENT environmental variable');


