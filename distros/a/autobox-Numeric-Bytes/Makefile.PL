use inc::Module::Install;

name        'autobox-Numeric-Bytes';
all_from    'lib/autobox/Numeric/Bytes.pm';

requires 'autobox'               => 2.55;
requires 'bigint'                => 0;

build_requires 'Test::More'      => 0;
build_requires 'Test::Base'      => 0;

use_test_base;
auto_install;
WriteAll;

