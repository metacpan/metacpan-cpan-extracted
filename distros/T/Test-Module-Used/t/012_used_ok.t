#!/usr/bin/perl -w
use strict;
use warnings;

use Test::Module::Used;
use File::Spec::Functions qw(catdir catfile);

my $used = Test::Module::Used->new(
    test_dir  => [catdir('testdata', 't')],
    lib_dir   => [catdir('testdata', 'lib')],
    meta_file => catfile('testdata', 'META4.yml'),
);

# Plack is required in META.yml4 but not used in testdata/lib/SampleModule.pm and It's ok in used_ok()
$used->used_ok();

