#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

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
use Test::More tests => 12;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Upfiles::FTPlazy;

#------------------------------------------------------------------------------
{
  my $want_version = 12;
  is ($App::Upfiles::FTPlazy::VERSION, $want_version, 'VERSION variable');
  is (App::Upfiles::FTPlazy->VERSION,  $want_version, 'VERSION class method');
  ok (eval { App::Upfiles::FTPlazy->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::Upfiles::FTPlazy->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $ftp = App::Upfiles::FTPlazy->new;
  is ($ftp->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $ftp->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $ftp->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#------------------------------------------------------------------------------
# cwd()

{
  my $ftp = App::Upfiles::FTPlazy->new;
  is ($ftp->{'want_dir'}, '/', "cwd() initial /");

  $ftp->cwd('..');
  is ($ftp->{'want_dir'}, '/', "cwd() / to ..");

  $ftp->cwd('foo/bar');
  is ($ftp->{'want_dir'}, '/foo/bar', "cwd() / to foo/bar");

  $ftp->cwd('..');
  is ($ftp->{'want_dir'}, '/foo', "cwd() /foo/bar to ..");

  $ftp->cwd('/new/dir');
  is ($ftp->{'want_dir'}, '/new/dir', "cwd() /foo to /new/dir");
}

exit 0;
