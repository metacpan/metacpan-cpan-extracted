#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Cwd;

my @INC_BACKUP = @INC;

my $dir = getcwd;
my $mydir = path(__FILE__)->parent->absolute;

chdir($mydir);
unshift @INC, 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

eval 'use lib::absolute -hard';

like($@,qr/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx of \@INC doesn't exist/,'Checking for -hard error');

chdir($dir);
@INC = @INC_BACKUP;

done_testing;
