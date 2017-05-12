use inc::Module::Install;

name     'WebService-Hatena-Fotolife';
author   'Kentaro Kuribayashi, <kentarok@cpan.org>';
license  'MIT';
all_from 'lib/WebService/Hatena/Fotolife.pm';

requires 'XML::Atom' => '0.11';
requires 'Image::Info';
requires 'OAuth::Lite';

test_requires 'Test::More' => 0.96;

repository 'http://github.com/kentaro/perl-webservice-hatena-fotolife';
bugtracker 'http://github.com/kentaro/perl-webservice-hatena-fotolife/issues';

auto_include_deps;
WriteAll;
