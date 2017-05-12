#!/usr/bin/perl -w

# Copyright 2016 Ryde

# This file is part of PodLinkCheck.
#
# PodLinkCheck is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# PodLinkCheck is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.


# Check the cpanminus 02packages.details.txt bsearch by looking up all of
# its entries.  Takes about 2 minutes for 160_000 or so modules.

use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::PodLinkCheck;
my $plc = App::PodLinkCheck->new;

#------------------------------------------------------------------------------

my $good = 1;
foreach my $filename ($plc->_cpanminus_packages_details_filenames()) {
  diag "filename: ",$filename;

  open my $fh, $filename or die;
  open my $bfh, $filename or die;

  my $re = qr/^([^ ]*[^ :]) /;
  my $count_total = 0;
  my $count_bad = 0;
  while (defined(my $line = readline $fh)) {
    $line =~ $re or next;
    my $module = $1;
    $count_total++;

    if ($count_total <= 3) {
      diag "module: >>",$module,"<<";
    }
    my $ret = App::PodLinkCheck::_packages_details_bsearch($bfh, $module);
    if (! $ret) {
      $count_bad++;
      if ($count_bad < 5) {
        diag "oops, _packages_details_bsearch() did not find >>",$module,"<<";
      }
    }
  }
  diag "count $count_total modules, $count_bad bad";
  if ($count_bad) { $good = 0; }
}
ok($good);

#------------------------------------------------------------------------------
exit 0;
