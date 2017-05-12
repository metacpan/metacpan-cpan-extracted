use strict;
use warnings;

use inc::Module::Install;
  
# Define metadata
name           'Tree-Predicate';
all_from       'lib/Tree/Predicate.pm';
  
# Specific dependencies
test_requires  'Test::More'  => '0.42';
  
WriteAll;
