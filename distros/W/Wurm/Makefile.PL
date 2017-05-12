#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(.);
use inc::Module::Install;

name     'Wurm';
license  'Nil';
all_from 'lib/Wurm.pm';

requires 'parent';
requires 'Plack';
requires 'Plack::Request';
requires 'Plack::Response';
requires 'Plack::Util::Accessor';
requires 'Scalar::Util';

test_requires 'Test::More';

auto_install;
WriteAll;
