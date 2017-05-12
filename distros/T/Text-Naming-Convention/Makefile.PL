use inc::Module::Install;

name     'Text-Naming-Convention';
all_from 'lib/Text/Naming/Convention.pm';
author   'sunnavy <sunnavy@bestpractical.com>';

build_requires 'Test::More';

auto_install;

WriteAll;

