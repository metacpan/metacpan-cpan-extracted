use inc::Module::Install;
name 'WebService-WebSequenceDiagrams';
all_from 'lib/WebService/WebSequenceDiagrams.pm';
requires 'WebService::Simple';
requires 'Class::Accessor::Fast';
build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
