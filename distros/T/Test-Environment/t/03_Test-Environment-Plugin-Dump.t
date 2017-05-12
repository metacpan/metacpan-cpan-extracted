#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 3 };
use Test::Differences;

use English '-no_match_vars';
use File::Slurp 'read_file';
use FindBin;

BEGIN {
	use_ok 'Test::Environment', qw{
		Dump
	};
}

my @dump = dump_with_name('dump01.txt');

eq_or_diff(\@dump, [ read_file($FindBin::Bin.'/dumps/dump01.txt') ], 'check reading of dump01.txt in array context');
eq_or_diff(join('', @dump), scalar read_file($FindBin::Bin.'/dumps/dump01.txt') , 'check reading of dump01.txt in scalar context');

