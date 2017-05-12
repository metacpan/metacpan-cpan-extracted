#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 2;

my $module='Test::GreaterVersion';

use_ok($module) or exit;
can_ok($module, 'has_greater_version');