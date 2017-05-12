use inc::Module::Install;
name 'autobox-Encode';
all_from 'lib/autobox/Encode.pm';

requires 'autobox' => 2.01;
requires 'Encode'  => 2.23;

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
