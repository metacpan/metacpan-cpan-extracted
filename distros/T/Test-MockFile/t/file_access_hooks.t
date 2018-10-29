#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp qw/tempfile tempdir/;

use Fcntl;

#use Errno qw/ENOENT EBADF/;

use Test::MockFile qw/strict/;    # Everything below this can have its open overridden.
my ( undef, $temp_file ) = tempfile();
my $temp_dir = tempdir( CLEANUP => 1 );

like( dies { open( my $fh, "<", $temp_file ) }, qr/^Use of open on unmocked file $temp_file in strict mode at $0 line \d+.\n$/, "Using open on an unmocked file throws a croak" );
like( dies { open( my $fh, "<abcd" ) }, qr/^Use of open on unmocked file <abcd in strict mode at $0 line \d+.\n$/, "Using a 2 arg open on an unmocked file throws a croak" );

like( dies { sysopen( my $fh, $temp_file, O_RDONLY ) }, qr/^Use of sysopen on unmocked file $temp_file in strict mode at $0 line \d+.\n$/, "Using sysopen on an unmocked file throws a croak" );

like( dies { opendir( my $fh, $temp_dir ) }, qr/^Use of opendir on unmocked file $temp_dir in strict mode at $0 line \d+.\n$/, "Using opendir on an unmocked directory throws a croak" );

# We can't test this because opendir with anything but 2 args chokes on compile. I'm nervous that older perls may not behave this way so I'm going to leave the prod code in.
#like( dies { opendir( my $fh, $temp_dir, $temp_dir ) }, qr/^Use of opendir on unmocked file $temp_dir in strict mode at $0 line \d+.\n$/, "Using opendir on an unmocked directory throws a croak" );

like( dies { -e '/abc' },    qr{^Use of stat on unmocked file /abc in strict mode at $0 line \d+.\n$},       "-e on an unmocked file throws a croak" );
like( dies { -e '' },        qr{^Use of stat on unmocked file  in strict mode at $0 line \d+.\n$},           "-e on an unmocked empty file name throws a croak" );
like( dies { -d $temp_dir }, qr{^Use of stat on unmocked file $temp_dir in strict mode at $0 line \d+.\n$},  "-d on an unmocked dir throws a croak" );
like( dies { -l $temp_dir }, qr{^Use of lstat on unmocked file $temp_dir in strict mode at $0 line \d+.\n$}, "-l on an unmocked dir throws a croak" );

done_testing();
