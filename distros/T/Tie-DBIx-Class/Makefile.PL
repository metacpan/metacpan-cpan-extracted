use inc::Module::Install;

name     'Tie-DBIx-Class';
all_from 'lib/Tie/DBIx/Class.pm';
author   'Sebastian Willing <sewi@cpan.org>';
license  'perl';

build_requires 'Test::More';
build_requires 'DBD::SQLite';
build_requires 'DBI';

requires 'DBIx::Class'	=> 0;
requires 'Tie::Hash'	=> 0;

auto_install;

WriteAll;

