use inc::Module::Install;
name 'Test-PPPort';
all_from 'lib/Test/PPPort.pm';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_include;
auto_set_repository;
WriteAll;
