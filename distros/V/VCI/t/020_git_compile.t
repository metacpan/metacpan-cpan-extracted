#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Support qw(feature_enabled all_modules);

plan skip_all => "git requirements not installed" if !feature_enabled('git');

my @vcs_modules = all_modules("lib/VCI/VCS/Git");
push(@vcs_modules, "VCI::VCS::Git");
plan tests => scalar(@vcs_modules);
use_ok($_) foreach @vcs_modules;