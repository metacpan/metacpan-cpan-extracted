use inc::Module::Install;

name	'XCAP-Client';
author q{Thiago Rondon <thiago@aware.com.br>};
license 'perl';
all_from 'lib/XCAP/Client.pm';
build_requires 'Test::More';
build_requires 'Test::UseAllModules';

requires 'Moose';
requires 'Moose::Util::TypeConstraints';
requires 'Data::Validate::URI';
requires 'LWP::UserAgent';
requires 'URI::Split';
requires 'HTTP::Status';
requires 'Test::UseAllModules';

auto_install;

WriteAll;

