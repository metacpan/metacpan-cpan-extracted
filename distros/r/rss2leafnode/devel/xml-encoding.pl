#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde
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
use Module::Load;

 my $xml_rss_class = 'XML::RSS';
# my $xml_rss_class = 'XML::RSS::LibXML';
Module::Load::load ($xml_rss_class);

my $feed = $xml_rss_class->new (encoding => 'ISO-8859-1');
#  encoding="UTF-8"
# 
my $xml = <<'HERE';
<?xml version="1.0" encoding="ISO-8859-1"?>
<rss version="2.0">
 <channel>
  <title>Some Title</title>
  <item>
   <title>Item One</title>
   <description>Some £ thing</description>
   <guid>http://foo.com/page.html</guid>
  </item>
  <item>
   <title>Item Two</title>
   <guid isPermaLink="false">1234</guid>
  </item>
  <item>
   <title>Item Three</title>
   <guid isPermaLink="true">http://foo.com/page.html</guid>
  </item>
 </channel>
</rss>
HERE

$feed->parse($xml);
if ($feed->can('encoding')) {
  print $feed->encoding,"\n";
}

require Data::Dumper;
print Data::Dumper->new([$feed],["feed"])->Indent(1)->Sortkeys(1)->Dump;

exit 0;

