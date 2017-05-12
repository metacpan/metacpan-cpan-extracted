use strict;
use warnings;
use inc::Module::Install;

name 'WWW-Dict';
all_from 'lib/WWW/Dict.pm';

requires
    'UNIVERSAL::require' => 0,
    'version' => 0;

build_requires 'Test::More' => 0;

auto_install;
WriteAll;
