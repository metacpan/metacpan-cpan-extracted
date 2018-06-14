#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd;

use Test::RequiredMinimumDependencyVersion;

main();

sub main {
    my $class = 'Test::RequiredMinimumDependencyVersion';

    for my $dir (qw(bin blib lib script t)) {
        my $cwd = cwd();
        _chdir( tempdir() );

        my $obj = $class->new( module => { 'XYZ' => '0.001' } );
        _mkdir($dir);
        my @expected;
        if ( $dir ne 't' ) {
            @expected = $dir;
        }

        #
        my @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if only '$dir' exists" );
        _chdir($cwd);
    }

    {
        my $cwd = cwd();
        _chdir( tempdir() );

        my $obj = $class->new( module => { 'XYZ' => '0.001' } );

        #
        my @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [], '_default_dirs() returns an empty array if nothing exists' );

        # lib
        _mkdir('lib');
        my @expected = 'lib';

        @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if the 'lib' dir exists" );

        # bin, lib
        _mkdir('bin');
        @expected = sort qw(bin lib);

        @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if the 'bin' and 'lib' dir exists" );

        # bin, blib
        _mkdir('blib');
        @expected = sort qw(bin blib);

        @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if the 'bin', 'lib' and 'blib' dir exists" );

        # bin, blib, script
        _mkdir('script');
        @expected = sort qw(bin blib script);

        @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if the 'bin', 'lib', 'blib' and 'script' dir exists" );

        _chdir($cwd);
    }

    #
    done_testing();

    exit 0;
}

sub _chdir {
    my ($dir) = @_;

    my $rc = chdir $dir;
    BAIL_OUT("chdir $dir: $!") if !$rc;
    return $rc;
}

sub _mkdir {
    my ($dir) = @_;

    my $rc = mkdir $dir;
    BAIL_OUT("mkdir $dir: $!") if !$rc;
    return $rc;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
