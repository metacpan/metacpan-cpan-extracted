#! /usr/bin/env perl
use inc::Module::Install;

name 'Test-Synchronized';
all_from 'lib/Test/Synchronized.pm';

requires 'Class::Accessor::Fast' => 0;

test_requires 'Test::Pod::Coverage' => 0;
test_requires 'Test::More' => 0;

WriteAll;
