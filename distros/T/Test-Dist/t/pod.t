#!/usr/bin/env perl

use strict;
use warnings;
use lib::abs '../lib';

use Test::More;
use Test::If
	sub { chdir lib::abs::path '..' },
	'Test::Pod 1.22',
;

all_pod_files_ok();
exit 0;
# kwalitee hacks
require Test::Pod;
require Test::NoWarnings;
