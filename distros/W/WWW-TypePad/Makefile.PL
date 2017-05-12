use inc::Module::Install;
use Module::Install::ReadmeFromPod;
use Module::Install::Repository;
use Module::Install::AuthorTests;

name 'WWW-TypePad';
all_from 'lib/WWW/TypePad.pm';
readme_from 'lib/WWW/TypePad.pm';
requires 'Any::Moose';
requires 'JSON';
requires 'Net::OAuth::Simple', 1.4;
build_requires 'Test::More';
author_tests('xt');
auto_set_repository;
WriteAll;
