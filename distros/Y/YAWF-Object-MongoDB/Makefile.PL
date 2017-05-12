use inc::Module::Install;

name     'YAWF-Object-MongoDB';
all_from 'lib/YAWF/Object/MongoDB.pm';
author   q{Sebastian Willing <sewi@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Data::Dumper' => 0;
requires 'MongoDB' => 0.32;

recommends 'YAWF'    => 0.01;
recommends 'MongoDB' => 0.43;

auto_install;

WriteAll;

