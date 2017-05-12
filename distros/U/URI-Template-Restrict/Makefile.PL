use inc::Module::Install;
name 'URI-Template-Restrict';
all_from 'lib/URI/Template/Restrict.pm';

requires 'Class::Accessor::Fast';
requires 'List::MoreUtils';
requires 'Unicode::Normalize';
requires 'URI';
requires 'URI::Escape';

tests 't/*.t';
test_requires 'Test::More';
test_requires 'Test::UseAllModules';
test_requires 'Test::Deep';
author_tests 'xt';
use_test_base;

auto_set_repository;
auto_include_deps;
WriteAll;
