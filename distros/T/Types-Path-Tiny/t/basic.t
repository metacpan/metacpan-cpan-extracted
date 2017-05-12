use strict;
use warnings;
use Test::More 0.96;

use File::Temp 0.18;
use File::pushd qw/tempd/;
use Path::Tiny;
use Types::Path::Tiny -types;

my $tf = File::Temp->new;
my $td = File::Temp->newdir;

my @cases = (
    # Path
    {
        label    => "coerce string to Path",
        type     => Path,
        input    => "./foo",
    },
    {
        label    => "coerce object to Path",
        type     => Path,
        input    => $tf,
    },
    {
        label    => "coerce array ref to Path",
        type     => Path,
        input    => [qw/foo bar/],
    },
    # AbsPath
    {
        label    => "coerce string to AbsPath",
        type     => AbsPath,
        input    => "./foo",
    },
    {
        label    => "coerce Path to AbsPath",
        type     => AbsPath,
        input    => path($tf),
    },
    {
        label    => "coerce object to AbsPath",
        type     => AbsPath,
        input    => $tf,
    },
    {
        label    => "coerce array ref to AbsPath",
        type     => AbsPath,
        input    => [qw/foo bar/],
    },
    # File
    {
        label    => "coerce string to File",
        type     => File,
        input    => "$tf",
    },
    {
        label    => "coerce object to File",
        type     => File,
        input    => $tf,
    },
    {
        label    => "coerce array ref to File",
        type     => File,
        input    => [$tf],
    },
    # Dir
    {
        label    => "coerce string to Dir",
        type     => Dir,
        input    => "$td",
    },
    {
        label    => "coerce object to Dir",
        type     => Dir,
        input    => $td,
    },
    {
        label    => "coerce array ref to Dir",
        type     => Dir,
        input    => [$td],
    },
    # AbsFile
    {
        label    => "coerce string to AbsFile",
        type     => AbsFile,
        input    => "$tf",
    },
    {
        label    => "coerce object to AbsFile",
        type     => AbsFile,
        input    => $tf,
    },
    {
        label    => "coerce array ref to AbsFile",
        type     => AbsFile,
        input    => [$tf],
    },
    # AbsDir
    {
        label    => "coerce string to AbsDir",
        type     => AbsDir,
        input    => "$td",
    },
    {
        label    => "coerce object to AbsDir",
        type     => AbsDir,
        input    => $td,
    },
    {
        label    => "coerce array ref to AbsDir",
        type     => AbsDir,
        input    => [$td],
    },
);

for my $c (@cases) {
    subtest $c->{label} => sub {
        my $wd       = tempd;
        my $type     = $c->{type};
        my $input    = $c->{input};
        my $expected = path( ref $input eq 'ARRAY' ? @$input : $input );
        $expected = $expected->absolute if $type =~ /^Abs/;

        my $output = eval { $type->assert_coerce( $input ); };
        is( $@, '', "object created without exception" );
        isa_ok( $output, "Path::Tiny", '$output' );
        is( $output, $expected, '$output is as expected' );
    };
}

done_testing;
#
# This file is part of Types-Path-Tiny
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
