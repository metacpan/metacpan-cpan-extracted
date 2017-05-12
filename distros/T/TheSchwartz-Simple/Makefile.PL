use inc::Module::Install;
name 'TheSchwartz-Simple';
all_from 'lib/TheSchwartz/Simple.pm';

requires 'DBI';
build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
