use inc::Module::Install;

name     'constant-def';
author   'Mons Anderson <mons@cpan.org>';
all_from 'lib/constant/def.pm';

build_requires 'Test::More';
build_requires 'ex::lib' => 0.03;

requires 'constant' => 1.05;

auto_install;

WriteAll;

