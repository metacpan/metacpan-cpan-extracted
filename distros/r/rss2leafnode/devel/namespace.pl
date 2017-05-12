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
my $w3 = 'http://www.w3.org/XML/1998/namespace';

sub xml_prefix {
  my ($elt) = @_;
  for (;;) {
    foreach my $attname ($elt->att_names) {
      if ($attname =~ /^xmlns:(.*)/) {
        my $prefix = $1;
        print "xml_prefix() consider $attname ",$elt->att($attname),"\n";
        if ($elt->att($attname) eq $w3) {
          return $prefix;
        }
      }
    }
    $elt = $elt->parent // last;
    print "xml_prefix() to parent\n";
  }
  print "xml_prefix() not found\n";
  return undef;
}

{
  my $xml = <<'HERE';
<x xmlns="http://www.w3.org/2005/Atom"
   xmlns:atom="http://www.w3.org/2005/Atom"
   xmlns:fff="http://foo.org">
  <fff:bar def="1" />
  <fff:quux xml:lang="en" xml:base="http://bas.com" atom:base="aaa" fff:base="2" />
</x>
HERE
  require XML::Twig;
  my $twig = XML::Twig->new
       (map_xmlns => {
                       'http://foo.org' => 'foo',
                       'http://def.org' => 'defa',
                       $w3 => 'xml',
                     })
    ;
  $twig->parse($xml);
  my $root = $twig->root;
  print $root->xml_string,"\n";

  my $elt = $root->first_descendant(qr/quux/);
  print $elt->tag,' ',join(' ',$elt->att_names),"\n";
  print "ns_prefix '", $elt->ns_prefix, "'\n";
  foreach my $prefix ($elt->current_ns_prefixes) {
    print "  '$prefix'  ",$elt->namespace($prefix),"\n";
  }
  print "namespace '", $elt->namespace, "'\n";
  print "namespace w3 '", $elt->namespace($w3), "'\n";
  print "namespace fff '", $elt->namespace('fff'), "'\n";

  my $prefix = xml_prefix($elt);
  print "pref ",$prefix//'undef',"\n";
  if (defined $prefix) {
    print "'${prefix}:base ",$elt->att("${prefix}:base"),"\n";
  } else {
    foreach my $attname ('xml:base', 'base') {
      print "'$attname' ",$elt->att($attname)//'undef',"\n";
    }
  }

  exit 0;
}
