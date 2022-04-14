#!/usr/bin/perl

# Test the cPanel::TaskQueue module.
#

use strict;

use Test::More tests => 2;
use cPanel::TaskQueue;
use File::Path ();
use File::Temp ();

my $tmpdir      = File::Temp->newdir();
my $missing_dir = "$tmpdir/task_queue_test";

# Test queue directory creation.
ok( cPanel::TaskQueue->new( { name => 'tasks', state_dir => $missing_dir } ), 'Cache created with missing dir' );
ok( -d $missing_dir,                                                          'created the state directory' );
