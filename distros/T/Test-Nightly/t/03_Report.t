#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 2;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly::Report' ) };

my @test_methods = qw(new run);

#==================================================
# Check module methods
#==================================================
can_ok('Test::Nightly::Report', @test_methods);

