#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde
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
use Module::Load;
use FindBin;
use Data::Dumper;


{
  my $class;
  $class = 'XML::RSS';
  $class = 'XML::RSS::LibXML';
  Module::Load::load ($class);

  my $feed = $class->new;
  $feed->parsefile("$FindBin::Bin/../samp/rss_v2_0_msgs.xml");
  # $feed->parsefile("$FindBin::Bin/../samp/1226789508");
  # $feed->parsefile("$FindBin::Bin/../samp/uploads.rdf");
  # $feed->parsefile("$ENV{HOME}/plagger/Plagger-0.7.17/t/samples/atom10-example.xml");

  my $channel = $feed->{'channel'};
  print Dumper($feed);

  print "language field:   ",$feed->{'language'}//'undef',"\n";
  print "language coderef: ",$feed->can('language')//'undef',"\n";
  print "language field:   ",$channel->{'language'}//'undef',"\n";
  print "language coderef: ",$channel->can('language')//'undef',"\n";

  my $items = $feed->{'items'};
  print "items ", $feed->{'items'}, "\n";
  my $item = $items->[0];
  print "item ", $item, "\n";
  print "item author method: ",$item->can('author'),"\n";
  exit 0;
}

{
  require XML::LibXML;
  my $parser = XML::LibXML->new;
  my $dom = XML::LibXML->load_xml
    (location => "$FindBin::Bin/../samp/1226789508",
    );
  print Dumper($dom);
  print $dom->{'rss'}->toString;
  exit 0;
}

