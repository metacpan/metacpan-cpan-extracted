#!/usr/bin/env perl

use v5.14;
use warnings;

use Test::Load::Helper;

assume_test_yaft_exports expect_use_class
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default expectations]]
	;

had_no_warnings;
done_testing;
