use inc::Module::Install;
name 'WWW-Shorten-ptl';
all_from 'lib/WWW/Shorten/ptl.pm';

requires 'WWW::Shorten::generic';
requires 'Exporter';
requires 'JSON::Any';
requires 'Carp';
requires 'URI';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Exception';
auto_set_repository;
auto_include;
WriteAll;
