#!/usr/bin/env perl
use inc::Module::Install;

name 'WebService-MyGengo';
all_from 'lib/WebService/MyGengo.pm';
readme_markdown_from 'lib/WebService/MyGengo.pm';
readme_from 'lib/WebService/MyGengo.pm';

requires 'Moose';
requires 'namespace::autoclean';
requires 'Moose::Util::TypeConstraints';
requires 'MooseX::NonMoose';
requires 'MooseX::Aliases';
requires 'MooseX::Types::DateTime';

requires 'DateTime';
requires 'DateTime::Format::Strptime';
requires 'namespace::autoclean';
requires 'Scalar::Util';
requires 'Throwable';

requires 'LWP::UserAgent';
requires 'URI';
requires 'HTTP::Response';
requires 'Digest::HMAC';
requires 'Digest::SHA1';
requires 'JSON';

test_requires 'Test::More' => '0.88';
test_requires 'FindBin';
test_requires 'Getopt::Long';
test_requires 'URI::Escape';

auto_install;
manifest_skip;
WriteAll;
