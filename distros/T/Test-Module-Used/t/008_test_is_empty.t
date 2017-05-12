#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Module::Used;
use File::Spec::Functions qw(catfile);

my $used = Test::Module::Used->new(
    test_dir  => [catfile('testdata', 't2')],
    lib_dir   => [catfile('testdata', 'lib2')],
    meta_file => catfile('testdata', 'META3.yml'),
    exclude_in_testdir => ['Test::Module::Used'],
);

$used->ok;
