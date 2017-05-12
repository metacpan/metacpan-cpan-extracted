use inc::Module::Install;

name 'Test-Requires-Env';
all_from 'lib/Test/Requires/Env.pm';

requires 'parent';
requires 'Test::Builder::Module';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;

auto_include;
WriteAll;
