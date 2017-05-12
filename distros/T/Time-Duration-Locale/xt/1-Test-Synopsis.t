#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More;

eval 'use Test::Synopsis; 1'
  or plan skip_all => "due to Test::Synopsis not available -- $@";

my $manifest = ExtUtils::Manifest::maniread();
my @files = grep m{^lib/.*\.pm$}, keys %$manifest;

if (! eval { require Time::Duration::sv }) {
  diag "skip Time::Duration::Filter since Time::Duration::sv not available -- $@";
  @files = grep {! m{/Time/Duration/Filter.pm} } @files;
}

plan tests => 1 * scalar @files;

Test::Synopsis::synopsis_ok(@files);
exit 0;
