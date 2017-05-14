#!/usr/bin/perl
#
# Copyright (C) 2011 by Opera Software Australia Pty Ltd
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

use strict;
use warnings;
use IO::File;
use lib 'lib';
use Test::Unit::TestRunner;

my $testrunner = Test::Unit::TestRunner->new();
$testrunner->start('Tree::Interval::Test');

