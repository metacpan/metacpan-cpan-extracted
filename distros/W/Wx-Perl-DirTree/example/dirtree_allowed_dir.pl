#!/usr/bin/perl

use strict;
use warnings;

use DirTreeTestAppAllowedDir;

my $app = DirTreeTestAppAllowedDir->new;
$app->MainLoop;
