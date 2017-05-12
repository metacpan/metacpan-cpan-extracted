use inc::Module::Install;
name 'autobox-DateTime-Duration';
all_from 'lib/autobox/DateTime/Duration.pm';

requires 'autobox';
requires 'DateTime';
requires 'DateTime::Duration';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
