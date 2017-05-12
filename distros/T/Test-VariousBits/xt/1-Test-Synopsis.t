#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Test-VariousBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More;
use ExtUtils::Manifest;

# uncomment this to run the ### lines
#use Smart::Comments;

eval 'use Test::Synopsis; 1'
  or plan skip_all => "due to Test::Synopsis not available -- $@";

my $manifest = ExtUtils::Manifest::maniread();
my @files = grep m{^lib/.*\.pm$}, keys %$manifest;

# Test::Weaken::Shm synopsis is a "perl -M"
@files = grep {! m</Test/Without/Shm\.pm$> } @files;

# Test::Without::GD synopsis is a "perl -M"
@files = grep {! m</Test/Without/GD\.pm$> } @files;

# Module::Util::Masked synopsis is a "perl -M"
@files = grep {! m</Module/Util/Masked\.pm$> } @files;

plan tests => 1 * scalar(@files);

## no critic (ProhibitCallsToUndeclaredSubs)
synopsis_ok(@files);

exit 0;
