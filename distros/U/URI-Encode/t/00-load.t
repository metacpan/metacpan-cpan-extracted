#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

# Autoflush ON
local $| = 1;

# Test _use_
use_ok('URI::Encode') || BAIL_OUT('Failed to load URI::Encode');
diag("Testing URI::Encode $URI::Encode::VERSION");

# Done
done_testing();
exit 0;
