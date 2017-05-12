#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Test::Module::Used;
use File::Spec::Functions qw(catfile);

my $used = Test::Module::Used->new(
    test_dir  => [catfile('testdata', 't2')],
    lib_dir   => [catfile('testdata', 'lib2')],
    meta_file => catfile('testdata', 'META3.yml'),
);


is_deeply([$used->_packages_in($used->_pm_files)], ['My::Test']);
$used->_get_packages;
is_deeply($used->{exclude_in_testdir}, ['Test::Module::Used', 'My::Test']);
is_deeply($used->{exclude_in_libdir}, ['My::Test']);

my $used1 = Test::Module::Used->new(
    test_dir  => [catfile('testdata', 't2')],
    lib_dir   => [catfile('testdata', 'lib2')],
    test_lib_dir => [catfile('testdata', 't2', 'lib')],
    meta_file => catfile('testdata', 'META3.yml'),
);

is_deeply([$used1->_packages_in($used1->_pm_files)], ['My::Test']);
is_deeply([$used1->_packages_in($used1->_pm_files_in_test)], ['My::Test2']);
$used1->_get_packages;
is_deeply($used1->{exclude_in_testdir}, ['Test::Module::Used', 'My::Test', 'My::Test2']);
is_deeply($used1->{exclude_in_libdir}, ['My::Test']);


done_testing;
