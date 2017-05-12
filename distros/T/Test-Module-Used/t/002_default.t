#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Test::Module::Used;
my $used = Test::Module::Used->new();

is_deeply($used->_test_dir, ['t']);#default directory for test
is_deeply($used->_lib_dir, ['lib']);
is($used->_meta_file, 'META.json');
is($used->_version, '5.008000');

done_testing;
