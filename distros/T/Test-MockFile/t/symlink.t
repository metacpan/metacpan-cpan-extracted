#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Test::MockFile;

my $dir  = Test::MockFile->dir('/foo');
my $file = Test::MockFile->file('/bar');
ok( !-d ('/foo'), 'Directory does not exist yet' );

my $symlink = Test::MockFile->symlink( '/bar', '/foo/baz' );
ok( -d ('/foo'), 'Directory now exists' );

{
    opendir my $dh, '/foo' or die $!;
    my @content = readdir $dh;
    closedir $dh or die $!;
    is(
        \@content,
        [qw< . .. baz >],
        'Directory with symlink content are correct',
    );
}

undef $symlink;

{
    opendir my $dh, '/foo' or die $!;
    my @content = readdir $dh;
    closedir $dh or die $!;
    is(
        \@content,
        [qw< . .. >],
        'Directory no longer has symlink',
    );
}

done_testing();
exit 0;
