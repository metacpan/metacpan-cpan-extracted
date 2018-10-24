#!perl

use strict;
use warnings;

use lib "lib";
use Test::MockStat ();
use Test::MockFile ();
use Test::MockFileTest ();

#$ENV{TEST_MOCKFILE_STRICT} = "qr/.../ qr/.../";
Test::MockFile::strict_mode( ignore => [ qr/.../, qr/.../]);

my $foo;
$foo = Test::MockFile->new("/tmp/foo", undef); # File not there
$foo = Test::MockFile->new("/tmp/foo", ''); # empty file
$foo = Test::MockFile->new("/var/cpanel/cpanel.config", "abc\n");
$foo = Test::MockFile->file("/var/cpanel/cpanel.config.cache", "abc\n");
$bar = Test::MockFileTest->new($foo, {...});

$foo = Test::MockFile->dir("/tmp/foo", {perms => 0755, ...} ); # File not there
$
open(my $fh, '<', '/tmp/foo');
print <$fh>;

Test::MockFileTest->new('/foo', { perms => 0755, owner => 0, group => 0, is_symlink => 1, symlin_is_broken => 0, symlink_points_to => '/bar/foo', } );

# Symlink
$foo = Test::MockFile->new("/tmp/foo", "abc\n", {is_symlink => 1)};

# Dangling Symlink
$foo = Test::MockFile->new("/tmp/foo", undef, {is_symlink => 1, points_to => '/foo/bar'});



