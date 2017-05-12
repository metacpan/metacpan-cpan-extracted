#!/usr/bin/env perl
# Turn off warnings using the standard name of the module.

use strict;
no warnings::everywhere qw(uninitialized void);
use warnings;
use Test::More qw(no_plan);

use lib::abs ('lib');
use_ok('minimal_warnings');

minimal_warnings::generate_only_some_warnings();

