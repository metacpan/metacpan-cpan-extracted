use inc::Module::Install;

name     'WWW-AtMovies';
all_from 'lib/WWW/AtMovies.pm';
author   q{Alec Chen <alec@cpan.org>};
license  'perl';

requires 'WWW::Mechanize';
requires 'HTML::TokeParser::Simple';
requires 'Moose';
build_requires 'Test::More';

auto_install;

WriteAll;

