use inc::Module::Install;

name     'WWW-Phanfare-Class';
all_from 'lib/WWW/Phanfare/Class.pm';
author   q{Soren Dossing <netcom@sauber.net>};
license  'perl';

test_requires 'Test::More';
test_requires 'Test::Pod::Coverage';
test_requires 'Pod::Coverage::Moose';
test_requires 'YAML::Syck';

requires 'WWW::Phanfare::API' => 0.08;
requires 'MooseX::Method::Signatures';
requires 'Cache::Memory';
requires 'Date::Parse';

auto_install;

WriteAll;

