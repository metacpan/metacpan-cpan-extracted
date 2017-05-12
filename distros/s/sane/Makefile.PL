BEGIN { require 5.010 }

use inc::Module::Install;
name 'sane';
all_from 'lib/sane.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => 0.98;
auto_set_repository;
auto_include;
WriteAll;
