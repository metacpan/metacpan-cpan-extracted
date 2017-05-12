use inc::Module::Install;

name     'URI-mid';
all_from 'lib/URI/mid.pm';
author   q{Dorian Taylor <dorian@cpan.org>};
license  'apache';

requires 'URI';

build_requires 'Test::More';

auto_install;

WriteAll;

