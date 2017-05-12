#!/usr/bin/env perl

use strict;
use warnings;
use lib::abs '../lib';

use Test::More;
use Test::If
	sub { $ENV{TEST_AUTHOR} },
	sub { chdir lib::abs::path '..' },
	'Test::Pod::Coverage 1.08',
	'Pod::Coverage 0.18',
;

all_pod_coverage_ok();
exit 0;
require Test::Pod::Coverage;
require Test::NoWarnings;
