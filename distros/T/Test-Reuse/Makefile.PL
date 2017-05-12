use inc::Module::Install;

name     'Test-Reuse';
all_from 'lib/Test/Reuse.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

