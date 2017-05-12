#!/usr/bin/perl -w

# Copyright 2010, 2013 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use FindBin;
use Data::Dumper;

{
  my $html = <<'HERE';
<html>
<body>
This is a para


</body>
</html>
HERE

# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para
# This is a para

  require HTML::FormatText;
  my $str = HTML::FormatText->format_string ($html,
                                             leftmargin => 0,
                                             rightmargin => 40);
  print $str;
  exit 0;
}

{
  my $html = <<'HERE';
<div>
  <ul>
  <xhtml:li> One </xhtml:li>
  <li> Two </li>
  <li> Three </li>
  </ul>
</div>
HERE

  require HTML::FormatText;
  my $str = HTML::FormatText->format_string ($html,
                                             leftmargin => 0,
                                             rightmargin => 999);
  print $str;
  exit 0;
}
