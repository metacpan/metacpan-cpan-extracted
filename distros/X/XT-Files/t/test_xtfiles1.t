#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Test::XTFiles;
use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'Test::XTFiles';

chdir 'corpus/empty' or die "chdir failed: $!";

is( XT::Files->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new();
isa_ok( $obj, CLASS(), 'new returned object' );

ok( XT::Files->_is_initialized(), '... and initializes the singleton' );

is_deeply( $obj->{_files}, [], '... _files returns an empty hash ref' );

my @files = $obj->files;
is( scalar @files, 0, 'files returns 0 files' );

@files = $obj->all_files;
is( scalar @files, 0, 'all_files returns 0 files' );

@files = $obj->all_module_files;
is( scalar @files, 0, 'all_module_files returns 0 files' );

@files = $obj->all_executable_files;
is( scalar @files, 0, 'all_executable_files returns 0 files' );

@files = $obj->all_perl_files;
is( scalar @files, 0, 'all_perl_files returns 0 files' );

@files = $obj->all_pod_files;
is( scalar @files, 0, 'all_pod_files returns 0 files' );

@files = $obj->all_test_files;
is( scalar @files, 0, 'all_test_files returns 0 files' );

done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
