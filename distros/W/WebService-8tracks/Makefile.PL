use inc::Module::Install;

name 'WebService-8tracks';
all_from 'lib/WebService/8tracks.pm';

requires 'Any::Moose';
requires 'JSON::XS';
requires 'LWP::UserAgent';
requires 'URI::Escape';
requires 'HTTP::Request';
requires 'HTTP::Status';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Deep';
test_requires 'Data::Section::Simple';

auto_set_repository;
auto_include;

WriteAll;
