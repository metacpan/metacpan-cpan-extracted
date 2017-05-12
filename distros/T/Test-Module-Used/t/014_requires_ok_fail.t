#!/usr/bin/perl -w
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Module::Used;
use File::Spec::Functions qw(catdir catfile);
use Test::Builder;
use Test::More;
my $used = Test::Module::Used->new(
    test_dir  => [catdir('testdata', 't')],
    lib_dir   => [catdir('testdata', 'lib')],
    meta_file => catfile('testdata', 'META4.yml'),
);


test_out("1..4");
test_out("ok 1 - check required module: Module::Used");
test_out("not ok 2 - check required module: Plack");
test_out("ok 3 - check required module: Test::Module::Used");
test_out("ok 4 - check required module: Test::Class");
$used->requires_ok();


my $builder = Test::Builder->new();
$builder->reset;# reset because plan is automatically set in Test::Module::Used.
test_test(skip_err=>1);

done_testing;

