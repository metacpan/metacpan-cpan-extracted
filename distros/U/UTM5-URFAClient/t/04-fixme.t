use strict;
use warnings;

use Test::More;

eval 'use Test::Fixme';
plan skip_all => 'Module Test::Fixme required for FIXME test' if $@;

run_tests(
	where => ['lib'],
	match => qw|FIXME|
);
