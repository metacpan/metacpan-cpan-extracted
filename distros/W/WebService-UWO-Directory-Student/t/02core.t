#!/usr/bin/perl -T

# t/02core.t
#  Core functionality tests that do not require Internet connectivity
#
# $Id: 02core.t 8216 2009-07-25 22:16:50Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

use WebService::UWO::Directory::Student;

# Check all core methods are defined
my @methods = (
  'new',

  # Public methods
  'lookup',

  # Private/internal methods
  '_query',
  '_parse',
);

# There is 1 non-method test
plan tests => (1 + scalar(@methods));

foreach my $meth (@methods) {
  ok(WebService::UWO::Directory::Student->can($meth),
    'Method "' . $meth . '" exists.');
}

# Test the constructor initialization
my $dir = WebService::UWO::Directory::Student->new;
isa_ok($dir, 'WebService::UWO::Directory::Student');
