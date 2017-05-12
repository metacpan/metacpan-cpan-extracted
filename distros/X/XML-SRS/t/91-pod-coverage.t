#!/usr/bin/perl -w
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use strict;
use warnings;
use Test::More;

BEGIN {

 # the below are all dependencies of Test::Pod::Coverage so should be OK
	eval <<USE;
use Test::Pod::Coverage 1.04;
require Pod::Coverage;
use Pod::Find qw(pod_where);
USE
	plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
}
plan skip_all => 'set TEST_POD to enable this test'
	unless $ENV{TEST_POD};

my @modules = all_modules;

plan tests => scalar @modules;

for my $module (@modules) {
	my $pc = Pod::Coverage->new(
		package      => $module,
		also_private => [qr/^((meta|BUILD)$|_)/],
	);

	my @naked  = $pc->naked;
	my $rating = $pc->coverage;

	if (@naked) {

		# if 'naked' subroutines appear in the SYNOPSIS,
		# that's OK
		my $location = pod_where( { -inc => 1 }, $module );
		my %naked = map { $_ => 1 } @naked;
		open POD, $location;
		while (<POD>) {
			if ( m{^=head1 SYNOPSIS$} .. m{^=\w+} ) {
				next if m{^=};
				delete $naked{$_} for m{(\w+)}g;
			}
		}
	} ## end if (@naked)
	if ( defined $rating ) {
		is( $rating * 100, 100, "POD Coverage of $module complete" );
	}
	else {
		my $why = $pc->why_unrated;
		my $nopublics = ( $why =~ "no public symbols defined" );
		ok( $nopublics, "POD coverage of $module complete" );
		my $verbose = $ENV{HARNESS_VERBOSE} || 0;
		diag("$module: $why") unless ( $nopublics && !$verbose );
	}

	my $s = @naked == 1 ? "" : "s";
	if (@naked) {
		diag(
			sprintf(
				"Coverage for %s is %3.1f%%, with %d naked "
					. "subroutine$s:",
				$module,
				$rating * 100,
				scalar @naked,
				)
		);
		diag("\t$_") for @naked;
	}
} ## end for my $module (@modules)
