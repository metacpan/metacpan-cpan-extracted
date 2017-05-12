#!/usr/bin/perl -T

# t/03fallback.t
#  Tests core functionality
#
# $Id: 03fallback.t 8620 2009-08-18 04:36:27Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

# Cannot 'use' because we might skip tests
require Test::NoWarnings;

eval {
  require DateTime;
};
if ($@) {
  plan skip_all => 'DateTime required to test fallback';
}

eval {
  require Test::Without::Module;
};
if ($@) {
  plan skip_all => 'Test::Without::Module required to test fallback ability';
}

plan tests => 2;

# Delay loading of test hooks
Test::NoWarnings->import();

# Hide the DateTime package
Test::Without::Module->import('DateTime');

use Video::FourCC::Info;

# Check that the date parsed is appropriate
my $codec = Video::FourCC::Info->new('CC12');

# If there is no DateTime, then the registered date will be a simple
# string
is($codec->registered, '1996-06-12', 'Intel YUV12 codec register date');
