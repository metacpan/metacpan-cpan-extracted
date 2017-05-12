use inc::Module::Install;

name     'XML-Assert';
all_from 'lib/XML/Assert.pm';
author   'Andrew Chilton <andychilton@gmail.com>';
repository 'git://github.com/catalyst/XML-Assert';

perl_version '5.010_000';

requires        "XML::LibXML" => 1.58;  # oldest tested
requires        "Any::Moose" => 0;

build_requires 'Test::More';
build_requires 'Test::Builder::Tester';
test_requires 'Test::Exception';

include 'Test::Exception';
include 'Sub::Uplevel';

auto_install;

WriteAll;

