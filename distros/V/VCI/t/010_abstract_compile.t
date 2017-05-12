#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Support qw(all_modules);

my @modules = all_modules('lib/VCI/Abstract');
push(@modules, 'VCI', 'VCI::Util');
plan tests => scalar(@modules);
use_ok($_) foreach @modules;
