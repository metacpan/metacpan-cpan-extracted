use inc::Module::Install;

name     'WWW-Hashdb';
all_from 'lib/WWW/Hashdb.pm';
author   'Tomohiro Hosaka <bokutin@cpan.org>';

build_requires 'Test::More';

requires 'Moose';
requires 'Params::Validate';
requires 'WWW::Mechanize';
requires 'Web::Scraper';

auto_install;

WriteAll;

