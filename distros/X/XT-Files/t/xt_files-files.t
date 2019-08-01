#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

use constant CLASS => 'XT::Files';

chdir 'corpus/dist1' or die "chdir failed: $!";

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

is( $obj->bin_dir('bin'),    undef, 'bin_dir returns undef' );
is( $obj->module_dir('lib'), undef, 'module_dir returns undef' );
is( $obj->test_dir('t'),     undef, 'test_dir returns undef' );

my @files = $obj->files;
is( scalar @files, 5, 'files returns 5 file objects' );
for my $i ( 0 .. $#files ) {
    isa_ok( $files[$i], 'XT::Files::File' );
}

my @file_names = map { $_->name } @files;
is_deeply( [@file_names], [ sort qw(t/test.t lib/world.pm lib/world.pod bin/hello.txt bin/world.txt) ], '... with the correct names' );

#
is( $obj->ignore_file('bin/hello.txt'), undef, 'ignore_file returns undef' );

@files = $obj->files;
is( scalar @files, 4, 'files returns 4 file objects' );
for my $i ( 0 .. $#files ) {
    isa_ok( $files[$i], 'XT::Files::File' );
}

@file_names = map { $_->name } @files;
is_deeply( [@file_names], [ sort qw(t/test.t lib/world.pm lib/world.pod bin/world.txt) ], '... with the correct names' );

#
$obj->exclude(qr{ [.] txt $ }x);

@files = $obj->files;
is( scalar @files, 3, 'files returns 3 file objects' );
for my $i ( 0 .. $#files ) {
    isa_ok( $files[$i], 'XT::Files::File' );
}

@file_names = map { $_->name } @files;
is_deeply( [@file_names], [ sort qw(t/test.t lib/world.pm lib/world.pod) ], '... with the correct names' );

#
$obj->exclude('^world\.');

@files = $obj->files;
is( scalar @files, 1, 'files returns 1 file objects' );
for my $i ( 0 .. $#files ) {
    isa_ok( $files[$i], 'XT::Files::File' );
}

@file_names = map { $_->name } @files;
is_deeply( [@file_names], [ sort qw(t/test.t) ], '... with the correct names' );

#
is( $obj->bin_file('does_not_exist'), undef, 'adding a non-existing file' );

@files = $obj->files;
is( scalar @files, 1, 'files returns 1 file objects' );

for my $i ( 0 .. $#files ) {
    isa_ok( $files[$i], 'XT::Files::File' );
}

@file_names = map { $_->name } @files;
is_deeply( [@file_names], [ sort qw(t/test.t) ], '... with the correct names' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
