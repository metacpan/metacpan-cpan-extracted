#!/usr/bin/perl

package VFSsimple::Drv::Test;

use VFSsimple::Base;
our @ISA = qw(VFSsimple::Base);

package main;

use Test::More tests => 6;
use File::Temp;

use_ok('VFSsimple');
use_ok('VFSsimple::Base');

my $tempfile = File::Temp->new(UNLINK => 0);
$tempfile->unlink_on_destroy(1);
my $root = $tempfile->filename . "/any";
my $vfs = VFSsimple->new($root, { vfs => 'Test' });
isa_ok($vfs, 'VFSsimple::Drv::Test');
is($vfs->root, $root, "return root of vfs properly");
is($vfs->archive_path, $tempfile->filename, "Can get archive path");
is($vfs->archive_subpath, '/any', "Can get archive subpath");
