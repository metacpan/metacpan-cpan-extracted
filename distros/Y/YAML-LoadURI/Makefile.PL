use inc::Module::Install;

name     'YAML-LoadURI';
all_from 'lib/YAML/LoadURI.pm';
author   'Fayland Lam <fayland@gmail.com>';
license  'perl';

requires 'LWP::Simple';
requires 'YAML::Any';

build_requires 'Test::More';
test_requires 'Test::MockModule';

auto_install;

WriteAll;

