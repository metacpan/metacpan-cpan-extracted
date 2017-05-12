#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2013 Kevin Ryde
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
use FindBin qw($Bin);
use XML::Atom::Feed;
$XML::Atom::ForceUnicode = 1;

require URI::file;
my $uri = URI::file->new
  ("/so/plagger/Plagger-0.7.17/t/samples/atom10-example.xml");

#$uri = URI::file->new ('/usr/share/doc/python-feedparser/docs/examples/atom10.xml');
$uri = URI::file->new ('/usr/share/doc/python-feedparser/docs/examples/atom03.xml');

my $xml = <<'HERE';
<?xml version="1.0"?>
<feed version="0.3" xmlns="http://purl.org/atom/ns#" xml:base="http://example.org/" xml:lang="en">
  <entry>
    <title>Item One</title>
    <author>
      <name>Foo Bar</name>
      <email>foo@example.com</email>
    </author>
  </entry>
</feed>
HERE
#my $atom = XML::Atom::Feed->new (\$xml);

my $atom = XML::Atom::Feed->new ($uri);

use Data::Dumper;
#print Dumper($atom);

print "title:     ",$atom->title//'(undef)',"\n";
print "title:     ",$atom->{'title'}//'(undef)',"\n";
{
  my $author = $atom->author;
  print "author:    R=",(ref $author)," ",$author//'(undef)',"\n";
  if (defined $author) {
    print "    name:  ",$author->name,"\n";
    print "    email: ",$author->email//'(undef)',"\n";
    print "    uri:   ",$author->uri//'(undef)',"\n";
  }
}
print "language:  ",$atom->language//'(undef)',"\n";

my $rights = $atom->rights;
print "rights:    ",$rights//'(undef)',"\n";
#print "          ",$rights->type,"\n";

my $copyright = $atom->copyright;
print "copyright: ",$copyright//'(undef)',"\n";
#print "          ",$copyright->type,"\n";

{
  my $generator = $atom->generator;
  print "generator: ",$generator//'(undef)',"\n";
}
foreach my $link ($atom->link) {
  # XML::Atom::Link, no pod
  print "link:   $link\n";
  print "        ",$link->type//'(undef)'," ",$link->rel//'(undef)'," ",$link->href,"\n";
}

foreach my $entry ($atom->entries) {
  # XML::Atom::Entry
  print "entry\n";
  #print Dumper($entry);
  print "  title:   ",$entry->title,"\n";
  {
    my $author = $entry->author;
    print "  author:  ",(defined $author ? "$author" : '(undef)'),"\n";
    if (defined $author) {
      print "    name:  ",$author->name,"\n";
      print "    email: ",$author->email//'(undef)',"\n";
      print "    uri:   ",$author->uri//'(undef)',"\n";
    }
  }
  print "  summary: ",$entry->summary//'(undef)',"\n";

  # XML::Atom::Content
  my $content = $entry->content;
  print "  content: ",$content//'(undef)',"\n";
  if (defined $content) {
    print "    type:  ",$content->type,"\n";
    print "    lang:  ",$content->lang,"\n";
    print "    body:  ",$content->body,"\n";
  }

  foreach my $link ($entry->link) {
    print "  link:   $link\n";
    print "          ",$link->type//'(undef)'," ",$link->rel//'(undef)'," ",$link->href,"\n";

  }
}
exit 0;

