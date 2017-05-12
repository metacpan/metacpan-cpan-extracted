use 5.009005;
use inc::Module::Install;
name 'dan';
all_from 'lib/dan.pm';

requires $_ for (qw/ Encode /);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
