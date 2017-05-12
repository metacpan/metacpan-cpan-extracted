use inc::Module::Install;
name 'Trigger';
all_from 'lib/Trigger.pm';
requires('Class::Accessor::Fast');

build_requires 'Test::More';
use_test_base;
auto_include;
auto_install;
WriteAll;
