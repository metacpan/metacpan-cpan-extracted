#!/usr/bin/env perl

use inc::Module::Install;

name     'Throwable-SysError';
license  'MIT';
all_from 'lib/Throwable/SysError.pm';

requires 'namespace::autoclean';
requires 'Errno';
requires 'Moo';
requires 'MooX::Types::MooseLike::Base';
requires 'Scalar::Util';
requires 'Throwable::Error';

test_requires 'Test::More';

auto_install;
WriteAll;
