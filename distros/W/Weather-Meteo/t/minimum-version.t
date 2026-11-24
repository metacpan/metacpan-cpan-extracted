#!perl -w

use strict;
use warnings;

# Makefile.PL promises Perl 5.10.0 (MIN_PERL_VERSION).  Nothing but this test
# checks that the code does not quietly use something newer, so check it.

use Test::DescribeMe qw(author);
use Test::Needs 'Test::MinimumVersion';

Test::MinimumVersion->import();

all_minimum_version_ok('5.010', { paths => ['lib', 'bin'] });
