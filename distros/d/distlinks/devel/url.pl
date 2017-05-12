#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use URI;

{
  my $url = 'foo.html#b%41r';
  my $uri = URI->new($url);
  print $uri->fragment, "\n";
  exit 0;
}
{
  my $url = 'http://localhost/foo/';
  $url = URI->new($url)->canonical;
  print "$url\n";
}
{
  my $url = 'http://localhost/foo';
  $url = URI->new($url)->canonical;
  print "$url\n";
}
