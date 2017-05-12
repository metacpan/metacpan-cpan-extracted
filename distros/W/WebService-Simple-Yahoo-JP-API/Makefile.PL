use inc::Module::Install;
name 'WebService-Simple-Yahoo-JP-API';
all_from 'lib/WebService/Simple/Yahoo/JP/API.pm';

# requires '';

requires('WebService::Simple');
tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
