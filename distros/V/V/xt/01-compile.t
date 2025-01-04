#!/usr/bin/perl -I.

use strict;
use warnings;

use t::Test::abeltje;

use File::Spec::Functions qw(:DEFAULT devnull);
use File::Find;

my @to_compile;
BEGIN {
    -d "lib" and find (sub {
	-f      or return;
	/\.pm$/ or return;
	push @to_compile => $File::Find::name;
	}, "./lib" );
    }

my $out = "2>&1";
$ENV{TEST_VERBOSE} or $out = sprintf "> %s 2>&1", devnull ();

is (system (qq{$^X  "-Ilib" "-c" "$_" $out}), 0, "perl -c '$_'") for @to_compile;

abeltje_done_testing ();
