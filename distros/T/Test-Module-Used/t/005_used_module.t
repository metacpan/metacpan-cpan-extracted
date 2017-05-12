#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile);
use Test::Module::Used;

my $used = Test::Module::Used->new(
    lib_dir    => [catfile('testdata', 'lib')],
    test_dir   => [catfile('testdata', 't')],
    perl_version => '5.008',
);
is_deeply([$used->_pm_files], [catfile('testdata', 'lib', 'SampleModule.pm')]);
is_deeply([$used->_test_files],   [catfile('testdata', 't', '001_test.t')]);
is_deeply([$used->_used_modules()], [qw(Module::Used Net::FTP Test::Module::Used)]);
is_deeply([$used->_used_modules_in_test()], [qw(Test::Class Test::More)]);# SampleModule is ignored
is($used->_version, '5.008');# used version

is_deeply( [$used->_remove_core(qw(Module::Used Net::FTP Test::Module::Used))],
           ['Module::Used', 'Test::Module::Used'] );



# exclude
my $used2 = Test::Module::Used->new(
    lib_dir    => [catfile('testdata', 'lib')],
    test_dir   => [catfile('testdata', 't')],
    exclude_in_libdir => ['Module::Used'],
    exclude_in_testdir   => ['Test::Class'],
);
is_deeply([$used2->_used_modules()], [qw(Net::FTP Test::Module::Used)]);
is_deeply([$used2->_used_modules_in_test()], [qw(SampleModule Test::More)]);

# exclude after constructed
my $used3 = Test::Module::Used->new(
    lib_dir  => [catfile('testdata', 'lib')],
    test_dir => [catfile('testdata', 't')],
);
$used3->push_exclude_in_libdir(qw(Module::Used Net::FTP));
is_deeply([$used3->_used_modules()], [qw(Test::Module::Used)]);
$used3->push_exclude_in_testdir( qw(Test::More Test::Class) );
is_deeply([$used3->_used_modules_in_test()], []);

# contains modules in test_dir (RT#54187)
my $used4 = Test::Module::Used->new(
    test_dir  => [catfile('testdata', 't2')],
    test_lib_dir => [catfile('testdata', 't2', 'lib')],
    lib_dir   => [catfile('testdata', 'lib2')],
    meta_file => catfile('testdata', 'META3.yml'),
);
is_deeply([$used4->_test_files],   [catfile('testdata', 't2', '001_use_ok.t'), catfile('testdata', 't2', 'lib', 'My', 'Test2.pm')]);
is_deeply([$used4->_remove_core($used4->_used_modules_in_test())], [qw(List::MoreUtils)]);

done_testing;
