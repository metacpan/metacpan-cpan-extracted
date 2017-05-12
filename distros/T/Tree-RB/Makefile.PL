use strict;
use warnings;
use inc::Module::Install;

# Define metadata
repository     'http://github.com/arunbear/perl5-red-black-tree';
name           'Tree-RB';
all_from       'lib/Tree/RB.pm';

# Specific dependencies
requires       'enum'        => 0;
test_requires  'Test::More'  => '0.42';

WriteAll;
