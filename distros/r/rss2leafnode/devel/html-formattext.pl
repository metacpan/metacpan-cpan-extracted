#!/usr/bin/perl -w

# Copyright 2007, 2010 Kevin Ryde
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

use strict;
use warnings;
use Data::Dumper;
use HTML::TreeBuilder;
use HTML::FormatText;

# <meta http-equiv=Content-Type content='text/html; charset=utf-8'>

my $html = "<html>
<head>
</head
<body>
&amp;
&#36;
&#176;
&#255;
&#256;
&cent;
\x{100}
&foobar;
x\x{A0}\x{AD}y
&hearts;
</body>
<html>
";

my $tree = HTML::TreeBuilder->new->parse($html);
$tree->eof;
my $formatter = HTML::FormatText->new(leftmargin => 0,
                                      rightmargin => 60);
my $text = $formatter->format($tree);

print Dumper \$text;
