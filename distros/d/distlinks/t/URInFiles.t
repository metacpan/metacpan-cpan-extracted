#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Distlinks.
#
# Distlinks is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More tests => 7;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Distlinks::URInFiles;

{
  my $want_version = 11;
  is ($App::Distlinks::URInFiles::VERSION, $want_version, 'VERSION variable');
  is (App::Distlinks::URInFiles->VERSION,  $want_version, 'VERSION class method');

  ok (eval { App::Distlinks::URInFiles->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::Distlinks::URInFiles->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# join_backslashed_newlines()

is (App::Distlinks::URInFiles::join_backslashed_newlines("abc\ndef"),
    "abc\ndef",
    'join_backslashed_newlines()');

is (App::Distlinks::URInFiles::join_backslashed_newlines("abc\\\ndef"),
    "\nabcdef",
    'join_backslashed_newlines()');

is (App::Distlinks::URInFiles::join_backslashed_newlines("abc\\\ndef\\\nghi"),
    "\n\nabcdefghi",
    'join_backslashed_newlines()');
    


exit 0;

