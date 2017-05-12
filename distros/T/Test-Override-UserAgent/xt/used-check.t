#!perl

use 5.008;
use strict;
use warnings 'all';

use Test::More;
use Test::Requires 0.02;

# Only authors get to run this test
plan skip_all => 'Set TEST_AUTHOR to enable this test'
	unless $ENV{'TEST_AUTHOR'} || -e 'inc/.author';

# Required modules for this test
test_requires 'Test::Module::Used' => '0.1.9';

# Make the testing object (and include xt/ tests since they are always run)
my $used = Test::Module::Used->new(
	test_dir => ['t', 'xt'],
);

# These are not actually required btu fool Kwalitee check
$used->push_exclude_in_testdir(qw[Test::Pod::Coverage Test::Pod]);

# Test that used in Makefile.PL, META.yml, and files all match
$used->ok;
