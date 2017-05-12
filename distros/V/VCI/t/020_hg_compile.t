#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Support qw(all_modules);

my @vcs_modules = all_modules("lib/VCI/VCS/Hg");
push(@vcs_modules, "VCI::VCS::Hg");
plan tests => scalar(@vcs_modules);
use_ok($_) foreach @vcs_modules;