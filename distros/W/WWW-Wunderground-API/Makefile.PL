use inc::Module::Install;

name     'WWW-Wunderground-API';
all_from 'lib/WWW/Wunderground/API.pm';
author   q{John Lifsey <nebulous@crashed.net>};
license  'perl';
homepage 'https://github.com/nebulous/WWW-Wunderground-API';
repository 'https://github.com/nebulous/WWW-Wunderground-API.git';

build_requires 'Test::More';

requires 'Moo'=>'1.001000';
requires 'LWP::Simple';
requires 'XML::Simple';
requires 'JSON::MaybeXS';
requires 'Hash::AsObject';
recommends 'CHI'=> '0.50';
recommends 'Cache::FileCache'=> 0;

auto_install;

WriteAll;

