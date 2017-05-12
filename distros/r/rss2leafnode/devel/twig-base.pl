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

my $xml = <<'HERE';
<feed>
  <entry xml:base="http://base.org">
    <title>Item One</title>
    <thr:in-reply-to ref="tag:foo.com,2010-02-09:something" />
  </entry>
  <entry xml:base="http://base.org">
    <title>Item Two</title>
  </entry>
</feed>
HERE

require XML::Twig;
my $twig = XML::Twig->new
  (start_tag_handlers => { _all_ => \&my_start_tag });

sub my_start_tag {
  my ($twig, $elt) = @_;
  say $elt->tag;
  say $elt->att('xml:base') // 'no xml:base';
  if (defined $elt->att('xml:base')) {
    $twig->base($elt->att('xml:base'));
  }
  my $p = $twig->{twig_parser};
  say " ",$p;
  say " ",$p->base//'undef';
  say " ", $twig->base//'undef', "\n";
}

$twig->parse($xml);
exit 0;
