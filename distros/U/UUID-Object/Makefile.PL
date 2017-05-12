use inc::Module::Install;

name 'UUID-Object';
all_from 'lib/UUID/Object.pm';

requires 'Exporter' => 5.562;
requires 'Carp' => 1.01;
requires 'MIME::Base64' => 2.12;

test_requires 'Test::More';
#use_test_base;

auto_include;

WriteAll;
