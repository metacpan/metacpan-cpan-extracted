use inc::Module::Install;

name     'self-init';
all_from 'lib/self/init.pm';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'ex::lib';
build_requires 'Test::More';
build_requires 'Test::NoWarnings';

requires 'Carp';

auto_install;

WriteAll;

