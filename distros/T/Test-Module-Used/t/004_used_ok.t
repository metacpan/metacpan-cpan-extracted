#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Module::Used;
use File::Spec::Functions qw(catfile);

my $used = Test::Module::Used->new(
    lib_dir    => [catfile('testdata', 'lib')],
    test_dir   => [catfile('testdata', 't')],
    meta_file  => catfile('testdata', 'META2.yml'),
    exclude_in_testdir => ['SampleModule'],
);

$used->ok;
