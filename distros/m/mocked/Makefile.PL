#!/usr/bin/perl -w
use warnings;
use strict;
use inc::Module::Install;

name            'mocked';
author          'Luke Closs <cpan@5thplane.com>';
build_requires  'Test::More'        => '0.42';
build_requires  'Test::Exception';
license         'perl';
version_from    'lib/mocked.pm';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
