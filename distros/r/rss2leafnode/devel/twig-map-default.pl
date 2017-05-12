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

use 5.010;
use strict;
use warnings;
use FindBin;
use Data::Dumper;

my $rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
my $atom = 'http://www.w3.org/2005/Atom';


{
  my $xml = <<'HERE';
<feed xmlns="http://www.w3.org/2005/Atom"
      xmlns:thr="http://purl.org/syndication/thread/1.0">
  <entry>
    <title>Item One</title>
    <updated>2006-03-01T12:12:12Z</updated>
    <thr:in-reply-to ref="tag:foo.com,2010-02-09:something" />
    <link rel="replies"
          href="http://foo.com/reply.html" thr:count="10"/>
  </entry>
</feed>
HERE

  require XML::Twig;
  my $twig = XML::Twig->new
    (map_xmlns => {$atom => 'atom'});
  $twig->parse($xml);
  print $twig->root->first_descendant(qr/entry/)->sprint, "\n";
  exit 0;
}

{
  my $xml = <<'HERE';
<x xmlns:abc="http://foo.org">
  <abc:bar def="1" />
  <quux abc:def="2" />
</x>
HERE
  require XML::Twig;
  my $twig = XML::Twig->new
    (map_xmlns => {'http://foo.org' => '#default'});
  $twig->parse($xml);
  print $twig->root->first_descendant('quux')->att_names, "\n";
  exit 0;
}


#my $filename = "$FindBin::Bin/" . "../samp/fondantfancies.atom";
my $filename = "$FindBin::Bin/" . "../samp/peter-martin.atom";

{
  require XML::Twig;

  my $twig = XML::Twig->new
    (map_xmlns => {$rdf => 'myrdf',
                   'http://purl.org/dc/elements/1.1/' => 'dc',
                   # 'http://www.w3.org/2005/Atom'      => '#default',
                  });
  $twig->safe_parsefile($filename)
    or die $@;

  my $root = $twig->root;
  foreach my $elem ($root->descendants(qr/link/)) {
    $elem->print;
    print "\n";
  }
  exit 0;
}
