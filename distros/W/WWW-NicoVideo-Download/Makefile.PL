use inc::Module::Install;
name 'WWW-NicoVideo-Download';
all_from 'lib/WWW/NicoVideo/Download.pm';

requires 'LWP::UserAgent';
requires 'Any::Moose';
requires 'CGI::Simple';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
WriteAll;
