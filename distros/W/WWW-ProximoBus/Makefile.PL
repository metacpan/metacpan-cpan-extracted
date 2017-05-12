use inc::Module::Install;
use Module::Install::ReadmeFromPod;
use Module::Install::AuthorTests;

name           'WWW-ProximoBus';
all_from       'lib/WWW/ProximoBus.pm';
readme_from    'lib/WWW/ProximoBus.pm';
requires 'Any::Moose';
requires 'JSON';
requires 'LWP::UserAgent';
build_requires 'Test::More';
author_tests('xt');
auto_set_repository;
WriteAll;
