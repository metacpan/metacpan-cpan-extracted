use inc::Module::Install;

name     'Tie-Hash-MongoDB';
all_from 'lib/Tie/Hash/MongoDB.pm';
author   q{Sebastian Willing <sewi@cpan.org>};
license  'perl';

build_requires 'Test::More';
build_requires 'IO::Socket';

requires 'MongoDB' => 0;
requires 'MongoDB::Connection' => 0;
requires 'MongoDB::OID' => 0;

auto_install;

WriteAll;

