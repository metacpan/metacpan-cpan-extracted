use inc::Module::Install;
name 'WWW-Shorten-RevCanonical';
all_from 'lib/WWW/Shorten/RevCanonical.pm';
requires 'LWP::UserAgent';
requires 'WWW::Shorten';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
