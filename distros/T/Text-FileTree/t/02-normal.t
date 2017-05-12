#!/usr/bin/perl
# Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings;
use strict;
use lib 't/lib';
use Test::Text::FileTree;

my $reffile = 't/data/reference';

my $ref = {
	'Makefile.PL' => {},
	'lib' => {
		'Text' => {
			'FileTree.pm' => {},
		},
	},
	't' => {
		'01-distribution.t' => {},
		'02-parse.t' => {},
	},
};

run_tests($reffile, $ref, [ platform => 'Unix' ]);
