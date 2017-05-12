#!/usr/bin/perl -w

use strict;
use Test::More;
plan skip_all => 'set TEST_LICENSE to enable this test'
	unless $ENV{TEST_LICENSE};
plan "no_plan";

use FindBin qw($Bin);
use File::Find;

find(
	sub {
		if (m{\.(pm|pl|t)$}) {
			open FILE, "<", $_ or die $!;
			while (<FILE>) {
				m{Copyright} && do {
					pass(
						"$File::Find::name mentions Copyright"
					);
					return;
				};
			}
			close FILE;
			fail("$File::Find::name missing license text");
		}
	},
	$Bin,
	"$Bin/../lib"
);

# Copyright (C) 2007  Sam Vilain
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
