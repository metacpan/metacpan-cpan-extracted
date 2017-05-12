use inc::Module::Install;

name        'autobox-Numeric-Time';
all_from    'lib/autobox/Numeric/Time.pm';

requires 'autobox'               => 2.55;

build_requires 'Test::More'      => 0;
build_requires 'Test::Base'      => 0;

use_test_base;
auto_install;
WriteAll;

