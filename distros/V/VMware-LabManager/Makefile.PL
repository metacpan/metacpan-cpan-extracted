use inc::Module::Install;

name     'VMware-LabManager';
all_from 'lib/VMware/LabManager.pm';
author   q{"Aditya Ivaturi" <"ivaturi@gmail.com">};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

