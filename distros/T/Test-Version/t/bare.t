#!/usr/bin/perl -T
use strict;
use warnings;
use Test::More tests => 1;
use Test::Version 'version_ok';

# if there are warnings emitted from calling
# version_ok without version_all_ok then
# they should be visible when testing.
# a la https://github.com/plicease/Test-Version/pull/5

version_ok 'corpus/pass/Foo.pm';
