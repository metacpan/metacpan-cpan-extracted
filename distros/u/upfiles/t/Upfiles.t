#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2017, 2020, 2024 Kevin Ryde

# This file is part of Upfiles.
#
# Upfiles is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Upfiles is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Upfiles.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use App::Upfiles;
use Test::More tests => 9;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

#------------------------------------------------------------------------------
{
  my $want_version = 16;
  is ($App::Upfiles::VERSION, $want_version, 'VERSION variable');
  is (App::Upfiles->VERSION,  $want_version, 'VERSION class method');
  ok (eval { App::Upfiles->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::Upfiles->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $upf = App::Upfiles->new;
  is ($upf->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $upf->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $upf->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#------------------------------------------------------------------------------
# new()

{
  my $upf = App::Upfiles->new;
  is ($upf->{'verbose'}, 1, "new() verbose default value");
}
{
  my $upf = App::Upfiles->new (verbose => 123);
  is ($upf->{'verbose'}, 123, "new() verbose specified");
}

exit 0;
