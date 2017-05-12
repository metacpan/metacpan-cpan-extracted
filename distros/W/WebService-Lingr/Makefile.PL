use inc::Module::Install;
name 'WebService-Lingr';
all_from 'lib/WebService/Lingr.pm';

requires 'Data::Visitor::Callback';
requires 'JSON::Syck';
requires 'LWP';
requires 'URI';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
