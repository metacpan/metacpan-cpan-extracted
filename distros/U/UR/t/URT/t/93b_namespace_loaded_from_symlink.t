#!/usr/bin/env perl 

use strict;
use warnings;
use Test::More tests => 7;
use Cwd;
use File::Temp;
use IO::File;

# Test the condition when one of the directories in @INC is a symlink, load a Namespace
# module from that directory, and make sure the entry in @INC and %INC have turned that
# path into an absolute path


my $temp_dir = File::Temp::tempdir(CLEANUP => 1);
ok($temp_dir, 'Create temp directory to hold symlink');

my $dir = Cwd::abs_path(File::Basename::dirname(__FILE__) . '/../../');
ok(-f $dir.'/Slimspace.pm', 'Found Slimspace.pm');

my $inc_dir = $temp_dir .'/inc';
ok(symlink($dir, $inc_dir), 'Create symlink');

unshift @INC, $inc_dir;
is($INC[0], $inc_dir, 'First in \@INC is the temp dir synlink');

use_ok('Slimspace');

my $path = $INC{'Slimspace.pm'};
my $abs_path = Cwd::abs_path($path);
is($path, $abs_path, '\%INC for Slimspace.pm is the absolute path');
is($INC[0], $dir, 'First in \@INC was rewritten to be absolute path');
