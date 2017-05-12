use inc::Module::Install;
name 'URI-Platonic';
all_from 'lib/URI/Platonic.pm';

requires 'Moose';
requires 'MooseX::Types::URI';
requires 'URI';

tests 't/*.t';
test_requires 'Test::More';
test_requires 'Test::use::ok';
author_tests 'xt';
use_test_base;

auto_include;
auto_install;
WriteAll;
