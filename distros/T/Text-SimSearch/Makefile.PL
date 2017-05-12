use inc::Module::Install;
name 'Text-SimSearch';
all_from 'lib/Text/SimSearch.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
