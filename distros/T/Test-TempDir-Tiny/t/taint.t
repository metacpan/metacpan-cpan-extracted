#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::TempDir::Tiny;

plan tests => 1;

my $work_dir = tempdir();

ok(-d $work_dir, 'Check if directory is created');
