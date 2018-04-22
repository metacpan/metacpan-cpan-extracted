#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd;

use Test::Pod::Links;

main();

sub main {
    my $class = 'Test::Pod::Links';

    for my $dir (qw(bin blib lib script t)) {
        my $cwd = cwd();
        chdir tempdir();

        my $obj = $class->new;
        mkdir $dir;
        my @expected;
        if ( $dir ne 't' ) {
            @expected = $dir;
        }

        #
        my @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if only '$dir' exists" );
        chdir $cwd;
    }

    {
        my $cwd = cwd();
        chdir tempdir();

        my $obj = $class->new;

        #
        my @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [], '_default_dirs() returns an empty array if nothing exists' );

        # lib
        mkdir 'lib';
        my @expected = 'lib';

        @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if the 'lib' dir exists" );

        # bin, lib
        mkdir 'bin';
        @expected = sort qw(bin lib);

        @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if the 'bin' and 'lib' dir exists" );

        # bin, blib
        mkdir 'blib';
        @expected = sort qw(bin blib);

        @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if the 'bin', 'lib' and 'blib' dir exists" );

        # bin, blib, script
        mkdir 'script';
        @expected = sort qw(bin blib script);

        @dirs = $obj->_default_dirs();
        is_deeply( [@dirs], [@expected], "_default_dirs() returns '@expected' if the 'bin', 'lib', 'blib' and 'script' dir exists" );

        chdir $cwd;
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
