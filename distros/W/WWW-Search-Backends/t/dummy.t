#!perl -w

# This test doesn't really do anything useful.  It's here mainly to
# prevent CPANPLUS from spitting out a warning about having no tests.

use Test::More tests => 2;

# Verify that our prereqs load OK:
use_ok('WWW::Search');

pass;
