#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use Env '$MYENV';
use Tie::TZ;

{
  for (;;) {
    local($MYENV) = 1; # no leak
  }
  exit 0;
}
{
  for (;;) {
    local($ENV{'bar'}) = 1; # no leak
  }
  exit 0;
}
{
  require Tie::Hash;
  my %foo;
  tie %foo => 'Tie::StdHash';
  for (;;) {
    local($foo{'bar'}) = 1; # leaks
  }
  exit 0;
}
{
  for (;;) {
    local $Tie::TZ::TZ = 'America/New_York';
  }
  exit 0;
}
