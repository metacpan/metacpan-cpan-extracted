package main;
use strict;
use warnings;
use utf8;
our $VERSION = eval { require version; version::qv('0.03') };

use inc::Module::Install;
eval {
    require ExtUtils::MakeMaker::Coverage;
    ExtUtils::MakeMaker::Coverage->import;
};

name 'WebService-Ustream-API';
version "$VERSION";
perl_version '5.006';
all_from 'lib/WebService/Ustream/API.pm';

requires 'version';
requires 'Class::Accessor::Fast';
requires 'LWP::UserAgent';
requires 'XML::Simple';

use_test_base;
auto_include;
auto_install;

WriteAll;
