#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use Cwd;

my @INC_BACKUP = @INC;

my $dir = getcwd;
my $mydir = file(__FILE__)->dir->absolute;

chdir($mydir->parent);
unshift @INC, 't';

eval 'use lib::absolute';

ok(grep { $_ eq $mydir } @INC,'Checking for absolute t directory in @INC');
ok(grep { $_ eq '.' } @INC,'Still having . in @INC');

chdir($dir);
@INC = @INC_BACKUP;

done_testing;
