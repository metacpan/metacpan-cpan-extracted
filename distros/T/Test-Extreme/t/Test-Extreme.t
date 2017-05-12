# There are two ways to run the tests. 
#
# If you have not run Makefile.PL you can run the tests directly as:
#     perl -I lib -w t/Test-Extreme.t
#
# Otherwise first build a makefile and then use make test:
#     perl Makefile.PL
#     make test

use strict;
use Test::Extreme;

run_tests_as_script 'Test::Extreme'; 
