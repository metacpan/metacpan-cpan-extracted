#!/usr/bin/perl -w
use strict;
use warnings;

use Test::Module::Used;
use File::Spec::Functions qw(catdir catfile);
use Test::Builder::Tester;
use Test::Builder;
use Test::More;

my $used = Test::Module::Used->new(
    test_dir  => [catdir('testdata', 't')],
    lib_dir   => [catdir('testdata', 'lib')],
    meta_file => catfile('testdata', 'META5.yml'),
);


test_out("1..3");
test_out("not ok 1 - check used module: Module::Used");
test_out("ok 2 - check used module: Test::Module::Used");
test_out("ok 3 - check used module: Test::Class");
$used->used_ok();

my $builder = Test::Builder->new();
$builder->reset;# reset because plan is automatically set in Test::Module::Used.
test_test(skip_err=>1);

done_testing;
