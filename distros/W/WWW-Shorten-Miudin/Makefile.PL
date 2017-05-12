use inc::Module::Install;

name	'WWW-Shorten-Miudin';
author q{Thiago Rondon <thiago@aware.com.br>};
license 'perl';
perl_version '5.10.0';
all_from 'lib/WWW/Shorten/Miudin.pm';
build_requires 'Test::More';
build_requires 'Test::UseAllModules';

requires 'WWW::Shorten';

auto_install;

WriteAll;

