use inc::Module::Install;

name     'nextgen';
all_from 'lib/nextgen.pm';
author   q{Evan Carroll <me@evancarroll.com>};
license  'perl';

perl_version '5.10.1';

build_requires 'Test::More';

requires 'indirect';
requires 'autodie';
requires 'B::Hooks::EndOfScope';
requires 'namespace::autoclean';
requires 'Moose';

requires 'if';
requires 'oose';
requires 'Filter::Simple';

requires 'IO::Handle';
requires 'mro';
requires 'utf8';
requires 'feature';
requires 'strict';
requires 'warnings';

resources
	repository   => 'git://github.com/EvanCarroll/nextgen.git'
	, homepage   => 'http://github.com/EvanCarroll/nextgen '
	, bugtracker => 'http://github.com/EvanCarroll/nextgen/issues'
	, license    => 'http://dev.perl.org/licenses/'
;

auto_install;

WriteAll;
