use inc::Module::Install;

name     'URI-ni';
abstract 
    'Implementation of the ni: URI scheme from RFC 6920';
all_from 'lib/URI/ni.pm';
author   q{Dorian Taylor <dorian@cpan.org>};
license  'apache';

requires 'URI';
requires 'Digest';
requires 'MIME::Base64';

build_requires 'Test::More';

auto_install;

WriteAll;

