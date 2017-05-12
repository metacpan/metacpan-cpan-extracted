#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Support qw(all_modules);

my @vcs_modules = all_modules("lib/VCI/VCS/Cvs");
push(@vcs_modules, "VCI::VCS::Cvs");
plan tests => scalar(@vcs_modules);
use_ok($_) foreach @vcs_modules;