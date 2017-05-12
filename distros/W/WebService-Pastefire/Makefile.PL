use inc::Module::Install;
name 'WebService-Pastefire';
all_from 'lib/WebService/Pastefire.pm';
readme_from 'lib/WebService/Pastefire.pm';
readme_markdown_from 'lib/WebService/Pastefire.pm';
readme_pod_from 'lib/WebService/Pastefire.pm';
githubmeta;

requires 'Class::Accessor::Fast';
requires 'LWP::Simple';
requires 'LWP::Protocol::https';

test_requires 'Sub::Uplevel';
test_requires 'Test::Exception';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
