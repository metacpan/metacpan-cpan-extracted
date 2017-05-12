#!/usr/bin/perl

use strict;
use warnings;

use DirTreeTestAppAllowedFile;

my $app = DirTreeTestAppAllowedFile->new;
$app->MainLoop;
