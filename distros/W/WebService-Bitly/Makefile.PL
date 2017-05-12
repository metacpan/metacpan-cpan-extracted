use strict;
use warnings;
use inc::Module::Install;

name     'WebService-Bitly';
author   'Yuki Shibazaki <shibayu36@gmail.com>';
all_from 'lib/WebService/Bitly.pm';

requires 'Carp';
requires 'URI';
requires 'URI::QueryParam';
requires 'LWP::UserAgent';
requires 'JSON';
requires 'Class::Accessor::Fast';
requires 'JSON';
requires 'UNIVERSAL::require';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::Class';
test_requires 'Path::Class';
test_requires 'Exporter';
test_requires 'FindBin';
test_requires 'URI';
test_requires 'HTTP::Response';
test_requires 'File::Basename';
test_requires 'Test::MockObject::Extends';
test_requires 'JSON';
test_requires 'LWP::UserAgent';

auto_install;
WriteAll;
