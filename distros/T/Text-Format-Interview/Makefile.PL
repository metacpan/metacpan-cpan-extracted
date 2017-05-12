use inc::Module::Install;

name     'Text-Format-Interview';
all_from 'lib/Text/Format/Interview.pm';
author   'Kieren Diment <zarquon@cpan.org>';
license  'perl';

build_requires 'Test::More';
requires 'Moose';
auto_install;

WriteAll;

