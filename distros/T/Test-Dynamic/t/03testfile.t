#!/usr/bin/perl -- -*-cperl-*-

use strict;
use warnings;
use Test::More qw/no_plan/;

#plan tests => 3;

eval { require Test::Dynamic; };
$@ and BAIL_OUT qq{Could not load the Test::Dynamic module: $@};
pass("Test::Dynamic module loaded");

my $testfile = "t/bucardo.testfile";
open my $fh, '<', $testfile
	or BAIL_OUT qq{Could not find test file "$testfile": $!\n};

my $count;

eval {
	$count = Test::Dynamic->count_tests();
};
like($@, qr{must be a hashref}, qq{Method count_tests with no argument fails});

eval {
	$count = Test::Dynamic->count_tests('foobar','baz');
};
like($@, qr{must be a hashref}, qq{Method count_tests with scalar arguments fails});

eval {
	$count = Test::Dynamic->count_tests({foo => 123});
};
like($@, qr{Need a filehandle}, qq{Method count_tests without "filehandle" key fails});

eval {
	$count = Test::Dynamic->count_tests
	(
	 {
	  filehandle  => $fh,
	  verbose     => 0,
	  skipuseline => 1,
	  local       => [qw(compare_tables)]
	  }
	 );
};
is($@, q{}, "Running count_tests ran successfully");

is($count, 476, "Method count_tests returned correct number of tests");

close $fh;
$testfile = "t/bucardo.testfile.2";
open $fh, '<', $testfile
	or BAIL_OUT qq{Could not find test file "$testfile": $!\n};

$count = Test::Dynamic->count_tests
	(
	 {
	  filehandle  => $fh,
	  verbose     => 0,
	  skipuseline => 1,
	  local       => [qw(compare_tables)]
	  }
	 );

is($count, 400, q{Method count_tests returned correct number of tests when $TEST_ vars are adjusted} );

close $fh;
$testfile = "t/bucardo.testfile.3";
open $fh, '<', $testfile
	or BAIL_OUT qq{Could not find test file "$testfile": $!\n};

$ENV{BUCARDO_TEST_NOCREATEDB} = 1;
$count = Test::Dynamic->count_tests
	(
	 {
	  filehandle  => $fh,
	  verbose     => 0,
	  skipuseline => 1,
	  local       => [qw(compare_tables)]
	  }
	 );

is($count, 460, q{Method count_tests returned correct number of tests when $ENV vars are adjusted} );

